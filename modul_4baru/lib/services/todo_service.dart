import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_item.dart';

class TodoService extends GetxService {
  static TodoService get to => Get.find();
  final SupabaseClient _supabase = Supabase.instance.client;

  late Box<TodoItem> _todoBox;
  final RxList<TodoItem> _todos = <TodoItem>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<TodoItem> get todos => _todos;
  bool get isLoading => _isLoading.value;

  // Computed properties
  List<TodoItem> get completedTodos => _todos.where((todo) => todo.isCompleted).toList();
  List<TodoItem> get incompleteTodos => _todos.where((todo) => !todo.isCompleted).toList();
  List<TodoItem> get overdueTodos => _todos.where((todo) => todo.isOverdue).toList();
  List<TodoItem> get dueTodayTodos => _todos.where((todo) => todo.isDueToday).toList();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initTodoBox();
    await loadTodos();
  }

  Future<void> _initTodoBox() async {
    try {
      _todoBox = await Hive.openBox<TodoItem>('todo_items');
      print('✅ Todo box initialized successfully');
    } catch (e) {
      print('❌ Error initializing todo box: $e');
      throw Exception('Failed to initialize todo storage');
    }
  }

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
      // Continue with the todo creation process even if profile creation fails
    }
  }

  Future<void> loadTodos() async {
    try {
      _isLoading.value = true;
      _todos.clear();

      // Load from Supabase (cloud)
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await _supabase
            .from('todos')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final cloudTodos = (response as List).map((json) {
          return TodoItem(
            id: json['id'].toString(),
            title: json['title'],
            description: json['description'],
            isCompleted: json['is_completed'] ?? false,
            priority: _parsePriority(json['priority'] ?? 'medium'),
            dueDate: json['due_date'] != null
                ? DateTime.parse(json['due_date'])
                : null,
            tags: List<String>.from(json['tags'] ?? []),
            createdAt: DateTime.parse(json['created_at']),
          );
        }).toList();

        _todos.addAll(cloudTodos);
            } else {
        // Fallback to local storage when not authenticated
        _todos.addAll(_todoBox.values.toList());
      }

      // Sort todos
      _sortTodos();

      print('✅ Loaded ${_todos.length} todos from cloud');
    } catch (e) {
      print('❌ Error loading todos from cloud: $e');

      // Fallback to local storage
      try {
        _todos.clear();
        _todos.addAll(_todoBox.values.toList());
        _sortTodos();
        print('✅ Loaded ${_todos.length} todos from local storage');
      } catch (localError) {
        print('❌ Error loading from local storage: $localError');
        Get.snackbar(
          'Error',
          'Failed to load todos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  int _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'very_low': return 1;
      case 'low': return 2;
      case 'medium': return 3;
      case 'high': return 4;
      case 'urgent': return 5;
      default: return 3;
    }
  }

  String _priorityToString(int priority) {
    switch (priority) {
      case 1: return 'very_low';
      case 2: return 'low';
      case 3: return 'medium';
      case 4: return 'high';
      case 5: return 'urgent';
      default: return 'medium';
    }
  }

  void _sortTodos() {
    _todos.sort((a, b) {
      // Completed items last
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // Overdue items next
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1;
      }

      // Then by priority (high to low)
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }

      // Finally by due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<TodoItem> addTodo({
    required String title,
    String? description,
    int priority = 3,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar(
          'Error',
          'Please login to add todos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        throw Exception('User not authenticated');
      }

      // First, ensure user profile exists in user_profiles table
      await _ensureUserProfileExists(userId);

      TodoItem todo;

        // Add to Supabase (cloud)
        final response = await _supabase.from('todos').insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'is_completed': false,
          'priority': _priorityToString(priority),
          'due_date': dueDate?.toIso8601String(),
          'tags': tags,
        }).select().single();

        todo = TodoItem(
          id: response['id'].toString(),
          title: response['title'],
          description: response['description'],
          isCompleted: response['is_completed'] ?? false,
          priority: _parsePriority(response['priority'] ?? 'medium'),
          dueDate: response['due_date'] != null
              ? DateTime.parse(response['due_date'])
              : null,
          tags: List<String>.from(response['tags'] ?? []),
          createdAt: DateTime.parse(response['created_at']),
        );

      _todos.insert(0, todo); // Insert at beginning
      _sortTodos();

      Get.snackbar(
        'Success',
        'Todo added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Added todo: ${todo.title}');

      // Force refresh todos from database to ensure consistency
      await Future.delayed(const Duration(milliseconds: 100));
      await loadTodos();
      return todo;
    } catch (e) {
      print('❌ Error adding todo: $e');
      Get.snackbar(
        'Error',
        'Failed to add todo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  Future<void> updateTodo(TodoItem todo) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId != null) {
        // Update in Supabase (cloud)
        await _supabase.from('todos').update({
          'title': todo.title,
          'description': todo.description,
          'is_completed': todo.isCompleted,
          'priority': _priorityToString(todo.priority),
          'due_date': todo.dueDate?.toIso8601String(),
          'tags': todo.tags,
        }).eq('id', todo.id).eq('user_id', userId);
      } else {
        // Fallback to local storage
        await _todoBox.put(todo.id, todo);
      }

      // Update the local list with the modified todo
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
      }

      _sortTodos();

      Get.snackbar(
        'Success',
        'Todo updated successfully',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      print('✅ Updated todo: ${todo.title}');
    } catch (e) {
      print('❌ Error updating todo: $e');
      Get.snackbar(
        'Error',
        'Failed to update todo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleTodoCompletion(String todoId) async {
    try {
      final todo = _todos.firstWhereOrNull((t) => t.id == todoId);
      if (todo != null) {
        final userId = _supabase.auth.currentUser?.id;
        final newStatus = !todo.isCompleted;

        if (userId != null) {
          // Update in Supabase (cloud)
          await _supabase.from('todos').update({
            'is_completed': newStatus,
          }).eq('id', todoId).eq('user_id', userId);
        } else {
          // Fallback to local storage
          todo.toggleCompleted();
          await _todoBox.put(todoId, todo);
        }

        todo.isCompleted = newStatus;
        _sortTodos();

        final message = todo.isCompleted ? 'Todo completed!' : 'Todo marked as incomplete';
        Get.snackbar(
          'Success',
          message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        print('✅ Toggled todo completion: ${todo.title}');
      }
    } catch (e) {
      print('❌ Error toggling todo: $e');
      Get.snackbar(
        'Error',
        'Failed to update todo status',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteTodo(String todoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId != null) {
        // Delete from Supabase (cloud)
        await _supabase.from('todos').delete().eq('id', todoId).eq('user_id', userId);
      } else {
        // Fallback to local storage
        await _todoBox.delete(todoId);
      }

      _todos.removeWhere((todo) => todo.id == todoId);

      Get.snackbar(
        'Success',
        'Todo deleted successfully',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      print('✅ Deleted todo: $todoId');
    } catch (e) {
      print('❌ Error deleting todo: $e');
      Get.snackbar(
        'Error',
        'Failed to delete todo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteCompletedTodos() async {
    try {
      final completedIds = completedTodos.map((todo) => todo.id).toList();
      final userId = _supabase.auth.currentUser?.id;

      if (userId != null) {
        // Delete from Supabase (cloud)
        for (final id in completedIds) {
          await _supabase.from('todos').delete().eq('id', id).eq('user_id', userId);
        }
      } else {
        // Fallback to local storage
        for (final id in completedIds) {
          await _todoBox.delete(id);
        }
      }

      _todos.removeWhere((todo) => todo.isCompleted);

      Get.snackbar(
        'Success',
        'Deleted ${completedIds.length} completed todos',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Deleted ${completedIds.length} completed todos');
    } catch (e) {
      print('❌ Error deleting completed todos: $e');
      Get.snackbar(
        'Error',
        'Failed to delete completed todos',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Search functionality
  List<TodoItem> searchTodos(String query) {
    if (query.isEmpty) return _todos;

    final lowerQuery = query.toLowerCase();
    return _todos.where((todo) =>
      todo.title.toLowerCase().contains(lowerQuery) ||
      (todo.description?.toLowerCase().contains(lowerQuery) ?? false) ||
      todo.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  // Filter by tags
  List<TodoItem> filterByTags(List<String> tags) {
    if (tags.isEmpty) return _todos;

    return _todos.where((todo) =>
      tags.any((tag) => todo.tags.contains(tag))
    ).toList();
  }

  // Get statistics
  Map<String, int> getStatistics() {
    return {
      'total': _todos.length,
      'completed': completedTodos.length,
      'incomplete': incompleteTodos.length,
      'overdue': overdueTodos.length,
      'dueToday': dueTodayTodos.length,
    };
  }
}