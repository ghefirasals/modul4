import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../services/auth_service.dart';

class NoteService extends GetxService {
  static NoteService get to => Get.find();
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxList<Note> _notes = <Note>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isUploading = false.obs;
  final RxString _errorMessage = ''.obs;

  final ImagePicker _imagePicker = ImagePicker();

  // Helper method to ensure user profile exists
  Future<void> _ensureUserProfileExists(String userId) async {
    try {
      // Check if user profile exists
      final existingProfile = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        // Create user profile if it doesn't exist
        final userData = await _supabase.auth.currentUser;
        await _supabase.from('user_profiles').insert({
          'id': userId,
          'username': userData?.userMetadata?['username'] ?? 'User_${userId.substring(0, 8)}',
          'full_name': userData?.userMetadata?['full_name'] ?? userData?.userMetadata?['name'] ?? 'User',
          'phone': userData?.userMetadata?['phone'],
          'address': userData?.userMetadata?['address'],
          'is_admin': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ Created user profile for user: $userId');
      }
    } catch (e) {
      print('❌ Error ensuring user profile exists: $e');
      // Continue with the note creation process even if profile creation fails
    }
  }

  // Getters
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading.value;
  bool get isUploading => _isUploading.value;
  String get errorMessage => _errorMessage.value;

  // Computed properties
  List<Note> get pinnedNotes => _notes.where((note) => note.isPinned).toList();
  List<Note> get unpinnedNotes => _notes.where((note) => !note.isPinned).toList();
  List<Note> get notesWithImages => _notes.where((note) => note.images.isNotEmpty).toList();

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadNotes();
  }

  Future<void> loadNotes() async {
    if (!AuthService.to.isLoggedIn) {
      _notes.clear();
      return;
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final userId = AuthService.to.currentUser!.id;
      final response = await Supabase.instance.client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      _notes.value = (response as List)
          .map((json) => Note.fromJson(json))
          .toList();

      print('✅ Loaded ${_notes.length} notes from Supabase');
        } catch (e) {
      print('❌ Error loading notes: $e');
      _errorMessage.value = 'Failed to load notes: $e';
      Get.snackbar(
        'Error',
        'Failed to load notes',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Note?> createNote({
    required String title,
    required String content,
    List<XFile> images = const [],
    bool isPinned = false,
  }) async {
    if (!AuthService.to.isLoggedIn) {
      Get.snackbar(
        'Error',
        'Please login to create notes',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final userId = AuthService.to.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First, ensure user profile exists in user_profiles table
      await _ensureUserProfileExists(userId);

      // Upload images first
      final imageUrls = <String>[];
      for (final image in images) {
        try {
          final url = await _uploadImageToStorage(image);
          if (url != null) {
            imageUrls.add(url);
          }
        } catch (e) {
          print('⚠️ Warning: Failed to upload image ${image.path}: $e');
          // Continue with other images even if one fails
        }
      }

      // Create note in database
      final noteData = {
        'user_id': userId,
        'title': title,
        'content': content,
        'images': imageUrls,
        'is_pinned': isPinned,
      };

      final response = await Supabase.instance.client
          .from('notes')
          .insert(noteData)
          .select()
          .single();

      final note = Note.fromJson(response);
      _notes.insert(0, note);
      _refresh(); // Ensure proper sorting and reactive update

      Get.snackbar(
        'Success',
        'Note created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Created note: ${note.title}');

      // Force refresh notes from database to ensure consistency
      await Future.delayed(const Duration(milliseconds: 100));
      await loadNotes();

      return note;
        } catch (e) {
      print('❌ Error creating note: $e');
      String errorMessage = 'Failed to create note';

      // More specific error messages
      if (e.toString().contains('bucket')) {
        errorMessage = 'Storage bucket not found. Please contact admin.';
      } else if (e.toString().contains('permission') || e.toString().contains('authorization')) {
        errorMessage = 'Permission denied. Please login again.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('user_profiles')) {
        errorMessage = 'User profile not found. Please logout and login again.';
      } else {
        errorMessage = 'Failed to create note: ${e.toString()}';
      }

      _errorMessage.value = errorMessage;
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
    return null;
  }

  Future<Note?> updateNote(
    String noteId, {
    String? title,
    String? content,
    List<XFile>? newImages,
    bool? isPinned,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final existingNote = _notes.firstWhereOrNull((note) => note.id == noteId);
      if (existingNote == null) {
        throw Exception('Note not found');
      }

      // Upload new images
      final imageUrls = <String>[];
      if (newImages != null) {
        for (final image in newImages) {
          final url = await _uploadImageToStorage(image);
          if (url != null) {
            imageUrls.add(url);
          }
        }
      }

      // Combine existing images with new ones - only add new images if provided
      final allImages = newImages != null
          ? [...existingNote.images, ...imageUrls]
          : existingNote.images;

      // Update note in database - always include current values or new values
      final updateData = <String, dynamic>{
        'title': title ?? existingNote.title,
        'content': content ?? existingNote.content,
        'images': allImages,
        'is_pinned': isPinned ?? existingNote.isPinned,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await Supabase.instance.client
          .from('notes')
          .update(updateData)
          .eq('id', noteId)
          .select()
          .single();

      final updatedNote = Note.fromJson(response);
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = updatedNote;
        _refresh();
      }

      Get.snackbar(
        'Success',
        'Note updated successfully',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      print('✅ Updated note: ${updatedNote.title}');
      return updatedNote;
        } catch (e) {
      print('❌ Error updating note: $e');
      _errorMessage.value = 'Failed to update note: $e';
      Get.snackbar(
        'Error',
        'Failed to update note',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
    return null;
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final note = _notes.firstWhereOrNull((n) => n.id == noteId);
      if (note != null) {
        // Delete images from storage
        for (final imageUrl in note.images) {
          await _deleteImageFromStorage(imageUrl);
        }
      }

      // Delete note from database
      await Supabase.instance.client
          .from('notes')
          .delete()
          .eq('id', noteId);

      _notes.removeWhere((n) => n.id == noteId);

      Get.snackbar(
        'Success',
        'Note deleted successfully',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      print('✅ Deleted note: $noteId');
    } catch (e) {
      print('❌ Error deleting note: $e');
      _errorMessage.value = 'Failed to delete note: $e';
      Get.snackbar(
        'Error',
        'Failed to delete note',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> togglePin(String noteId) async {
    try {
      final note = _notes.firstWhereOrNull((n) => n.id == noteId);
      if (note != null) {
        // Update in database first
        await Supabase.instance.client
            .from('notes')
            .update({'is_pinned': !note.isPinned})
            .eq('id', noteId);

        // Update local list after successful database update
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = note.copyWith(isPinned: !note.isPinned);
          _refresh();
        }

        Get.snackbar(
          'Success',
          note.isPinned ? 'Note unpinned' : 'Note pinned',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        print('✅ Toggled pin for note: ${note.title}');
      }
    } catch (e) {
      print('❌ Error toggling pin: $e');
      _errorMessage.value = 'Failed to update note';
      Get.snackbar(
        'Error',
        'Failed to update note',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String?> _uploadImageToStorage(XFile image) async {
    try {
      _isUploading.value = true;

      final userId = AuthService.to.currentUser!.id;
      final fileExt = image.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'notes/$userId/$fileName';

      final file = File(image.path);
      final bytes = await file.readAsBytes();

      // Validate file extension
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!validExtensions.contains(fileExt)) {
        print('❌ Invalid file extension: $fileExt');
        return null;
      }

      // Check file size (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        print('❌ File too large: ${bytes.length} bytes');
        return null;
      }

      try {
        await Supabase.instance.client.storage
            .from('note-images')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                contentType: _getContentType(fileExt),
                upsert: true,
              ),
            );

        print('✅ Image uploaded successfully: $filePath');

        // Get public URL for the uploaded image
        final publicUrl = Supabase.instance.client.storage
            .from('note-images')
            .getPublicUrl(filePath);

        print('✅ Public URL generated: $publicUrl');
        return publicUrl;
      } on StorageException catch (e) {
        print('❌ StorageException: ${e.error}');
        if (e.error == 'Storage bucket not found') {
          print('⚠️ Warning: Storage bucket "note-images" not found. Images will not be saved.');
          // Don't throw exception, just return null so note creation can continue
          return null;
        }
        return null;
      } catch (e) {
        print('❌ Error uploading image to storage: $e');
        // Don't throw exception, just return null so note creation can continue
        return null;
      }
    } catch (e) {
      print('❌ Image upload failed: $e');
      return null;
    } finally {
      _isUploading.value = false;
    }
  }

  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      final Uri uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final storagePath = pathSegments.skipWhile((segment) => segment != 'note-images').join('/');

      if (storagePath.isNotEmpty) {
        await Supabase.instance.client.storage
            .from('note-images')
            .remove([storagePath]);
        print('✅ Deleted image: $storagePath');
      }
    } catch (e) {
      print('❌ Error deleting image: $e');
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void _refresh() {
    // Trigger reactive update and sort notes: pinned first, then by updated_at
    _notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    // Force UI update by creating a new list reference
    _notes.assignAll(_notes);
  }

  Future<List<XFile>> pickImages({int maxImages = 5}) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        limit: maxImages,
        imageQuality: 80,
      );
      return images;
    } catch (e) {
      print('❌ Error picking images: $e');
      Get.snackbar(
        'Error',
        'Failed to pick images',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return [];
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Search functionality
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;

    final lowerQuery = query.toLowerCase();
    return _notes.where((note) =>
      note.title.toLowerCase().contains(lowerQuery) ||
      note.content.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get note by ID
  Note? getNoteById(String id) {
    return _notes.firstWhereOrNull((note) => note.id == id);
  }

  void clearError() {
    _errorMessage.value = '';
  }
}