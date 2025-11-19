import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/note_service.dart';
import '../../models/note.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    final noteService = Get.find<NoteService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Kembali'
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Get.find<NoteService>().loadNotes();
              Get.snackbar(
                'Success',
                'Notes refreshed',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 1),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                    if (_searchQuery.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Notes grid/list
          Expanded(
            child: Obx(() {
              final filteredNotes = _searchQuery.value.isEmpty
                  ? noteService.notes
                  : noteService.searchNotes(_searchQuery.value);

              if (noteService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (filteredNotes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 64,
                        color: Get.theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes found',
                        style: Get.theme.textTheme.titleMedium?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.value.isEmpty
                            ? 'Tap the + button to add a new note'
                            : 'Try a different search term',
                        style: Get.theme.textTheme.bodyMedium?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildNotesList(filteredNotes);
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showNoteDetail(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Get.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    const Icon(Icons.push_pin, color: Colors.amber, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.excerpt,
                style: Get.theme.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
                const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    note.timeAgo,
                    style: Get.theme.textTheme.bodySmall?.copyWith(
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          Get.find<NoteService>().togglePin(note.id!);
                          break;
                        case 'edit':
                          _showEditNoteDialog(note);
                          break;
                        case 'delete':
                          _showDeleteDialog(note);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isPinned ? 'Unpin' : 'Pin'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    _showNoteDialog();
  }

  void _showEditNoteDialog(Note note) {
    _showNoteDialog(note: note);
  }

  void _showNoteDialog({Note? note}) {
    final titleController = TextEditingController(text: note?.title);
    final contentController = TextEditingController(text: note?.content);
    bool isPinned = note?.isPinned ?? false;
    bool isLoading = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(note == null ? 'Add Note' : 'Edit Note'),
            content: SizedBox(
              width: Get.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Pin Note'),
                      value: isPinned,
                      onChanged: (value) => setState(() => isPinned = value ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (titleController.text.trim().isEmpty || isLoading)
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        try {
                          if (note == null) {
                            await Get.find<NoteService>().createNote(
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                              isPinned: isPinned,
                            );

                            Get.snackbar(
                              'Success',
                              'Note created successfully',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          } else {
                            await Get.find<NoteService>().updateNote(
                              note.id!,
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                              isPinned: isPinned,
                            );

                            Get.snackbar(
                              'Success',
                              'Note updated successfully',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          }

                          Get.back();
                        } catch (e) {
                          print('Error saving note: $e');
                          Get.snackbar(
                            'Error',
                            'Failed to save note: ${e.toString()}',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(note == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNoteDetail(Note note) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(note.title)),
            if (note.isPinned) const Icon(Icons.push_pin, color: Colors.amber),
          ],
        ),
        content: SizedBox(
          width: Get.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  note.content,
                  style: Get.theme.textTheme.bodyLarge,
                ),
                  const SizedBox(height: 16),
                Text(
                  'Created: ${note.createdAt.toString().substring(0, 19)}',
                  style: Get.theme.textTheme.bodySmall,
                ),
                if (note.updatedAt != note.createdAt)
                  Text(
                    'Updated: ${note.updatedAt.toString().substring(0, 19)}',
                    style: Get.theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showEditNoteDialog(note);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Note note) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Get.find<NoteService>().deleteNote(note.id!);
                Get.back();
                Get.snackbar(
                  'Success',
                  'Note deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete note',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}