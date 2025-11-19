import 'dart:async';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<User?> _currentUser = Rx<User?>(null);
  final Rx<UserProfile?> _userProfile = Rx<UserProfile?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  User? get currentUser => _currentUser.value;
  UserProfile? get userProfile => _userProfile.value;
  bool get isLoggedIn => _currentUser.value != null;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isAdmin => _userProfile.value?.isAdmin ?? false;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _isLoading.value = true;

      // Get current user from Supabase Auth
      final user = SupabaseConfig.client.auth.currentUser;
      _currentUser.value = user;

      if (user != null) {
        // Fetch user profile from database
        await _fetchUserProfile(user.id);
      }

      // Listen to auth changes
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn) {
          _currentUser.value = session?.user;
          if (session?.user != null) {
            _fetchUserProfile(session!.user.id);
          }
        } else if (event == AuthChangeEvent.signedOut) {
          _currentUser.value = null;
          _userProfile.value = null;
        }
      });
    } catch (e) {
      _errorMessage.value = 'Failed to initialize authentication: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      _userProfile.value = UserProfile.fromJson(response);
        } catch (e) {
      print('Error fetching user profile: $e');
      // If profile doesn't exist, create one
      await _createUserProfile(userId);
    }
  }

  Future<void> _createUserProfile(String userId) async {
    try {
      final user = _currentUser.value;
      if (user == null) return;

      final profileData = {
        'id': userId,
        'username': user.email?.split('@')[0] ?? 'user_${userId.substring(0, 8)}',
        'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
        'phone': user.userMetadata?['phone'],
        'address': user.userMetadata?['address'],
        'is_admin': false,
      };

      final response = await SupabaseConfig.client
          .from('user_profiles')
          .insert(profileData)
          .select()
          .single();

      _userProfile.value = UserProfile.fromJson(response);
        } catch (e) {
      print('Error creating user profile: $e');
      _errorMessage.value = 'Failed to create user profile: $e';
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        // User profile will be created automatically when they sign in
        return true;
      } else {
        _errorMessage.value = 'Failed to create account';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage.value = e.message;
      return false;
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser.value = response.user;
        await _fetchUserProfile(response.user!.id);
        return true;
      } else {
        _errorMessage.value = 'Invalid email or password';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage.value = e.message;
      return false;
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.nasipadang://login-callback',
      );

      return true;
    } on AuthException catch (e) {
      _errorMessage.value = e.message;
      return false;
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage.value = e.message;
      return false;
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      _currentUser.value = null;
      _userProfile.value = null;
      _errorMessage.value = '';
    } catch (e) {
      _errorMessage.value = 'Failed to sign out: $e';
    }
  }

  Future<void> logout() async {
    await signOut();
  }

  Future<bool> updateProfile({
    String? username,
    String? fullName,
    String? phone,
    String? address,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final userId = _currentUser.value?.id;
      if (userId == null) {
        _errorMessage.value = 'User not authenticated';
        return false;
      }

      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await SupabaseConfig.client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

        _userProfile.value = UserProfile.fromJson(response);
        return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update profile: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _errorMessage.value = '';
  }
}