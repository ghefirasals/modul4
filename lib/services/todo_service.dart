import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_item.dart';

class TodoService extends GetxService {
  Box<TodoItem>? _todoBox;
  final RxList<TodoItem> todos = <TodoItem>[].obs;

  bool get isInitialized => _todoBox != null;

  // Observable filter states
  final RxString selectedCategory = 'Semua'.obs;
  final RxString selectedStatus = 'Semua'.obs;
  final RxString sortBy = 'Tanggal Dibuat'.obs;

  // Getters
  List<String> get availableCategories {
    if (_todoBox == null) return [];
    final categories = <String>{};
    for (var todo in todos) {
      if (todo.category != null && todo.category!.isNotEmpty) {
        categories.add(todo.category!);
      }
    }
    return categories.toList()..sort();
  }

  List<TodoItem> get filteredTodos {
    var filtered = List<TodoItem>.from(todos);

    // Filter by category
    if (selectedCategory.value != 'Semua') {
      filtered = filtered.where((todo) => todo.category == selectedCategory.value).toList();
    }

    // Filter by status
    if (selectedStatus.value != 'Semua') {
      if (selectedStatus.value == 'Selesai') {
        filtered = filtered.where((todo) => todo.isCompleted).toList();
      } else if (selectedStatus.value == 'Belum Selesai') {
        filtered = filtered.where((todo) => !todo.isCompleted).toList();
      }
    }

    // Sort
    switch (sortBy.value) {
      case 'Tanggal Dibuat':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Nama':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Prioritas':
        filtered.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'Status':
        filtered.sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));
        break;
    }

    return filtered;
  }

  int get completedCount {
    if (_todoBox == null) return 0;
    return todos.where((todo) => todo.isCompleted).length;
  }

  int get pendingCount {
    if (_todoBox == null) return 0;
    return todos.where((todo) => !todo.isCompleted).length;
  }

  double get completionPercentage {
    if (_todoBox == null || todos.isEmpty) return 0.0;
    return (completedCount / todos.length) * 100;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initTodoBox();
    _loadTodos();
  }

  Future<void> _initTodoBox() async {
    _todoBox = await Hive.openBox<TodoItem>('todo_items');
  }

  void _loadTodos() {
    if (_todoBox != null) {
      // PENTING: Buat list baru agar GetX detect perubahan
      todos.value = List<TodoItem>.from(_todoBox!.values);
    }
  }

  // CRUD Operations
  Future<void> addTodo({
    required String title,
    String? description,
    int priority = 2,
    String? category,
  }) async {
    final todo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      priority: priority,
      category: category,
    );

    await _todoBox!.put(todo.id, todo);
    _loadTodos();

    Get.snackbar(
      '✅ Berhasil',
      'Todo berhasil ditambahkan',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> updateTodo(TodoItem todo) async {
    await todo.save();
    _loadTodos();

    Get.snackbar(
      '✅ Berhasil',
      'Todo berhasil diperbarui',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> deleteTodo(String todoId) async {
    if (_todoBox != null) {
      await _todoBox!.delete(todoId);
      _loadTodos();

      Get.snackbar(
        '🗑️ Berhasil',
        'Todo berhasil dihapus',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> toggleTodoCompletion(String todoId) async {
    if (_todoBox != null) {
      final todo = _todoBox!.get(todoId);
      if (todo != null) {
        todo.toggleCompletion();
        await todo.save();
        _loadTodos();
      }
    }
  }

  Future<void> clearCompletedTodos() async {
    if (_todoBox != null) {
      final completedTodos = _todoBox!.values.where((todo) => todo.isCompleted).toList();
      for (var todo in completedTodos) {
        await _todoBox!.delete(todo.id);
      }
      _loadTodos();

      Get.snackbar(
        '✅ Berhasil',
        '${completedTodos.length} todo selesai telah dihapus',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> clearAllTodos() async {
    if (_todoBox != null) {
      await _todoBox!.clear();
      _loadTodos();

      Get.snackbar(
        '✅ Berhasil',
        'Semua todo telah dihapus',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Filter methods - DIPERBAIKI: Mutual exclusive
  void setCategoryFilter(String category) {
    selectedCategory.value = category;
  }

  void setStatusFilter(String status) {
    selectedStatus.value = status;
  }

  void setSortBy(String sortByValue) {
    sortBy.value = sortByValue;
  }

  void clearFilters() {
    selectedCategory.value = 'Semua';
    selectedStatus.value = 'Semua';
    sortBy.value = 'Tanggal Dibuat';
  }

  // Statistics
  Map<String, int> getTodosByPriority() {
    if (_todoBox == null) return {'Rendah': 0, 'Sedang': 0, 'Tinggi': 0};

    final priorities = {1: 0, 2: 0, 3: 0}; // Low, Medium, High

    for (var todo in _todoBox!.values) {
      priorities[todo.priority] = (priorities[todo.priority] ?? 0) + 1;
    }

    return {
      'Rendah': priorities[1]!,
      'Sedang': priorities[2]!,
      'Tinggi': priorities[3]!,
    };
  }

  Map<String, int> getTodosByCategory() {
    if (_todoBox == null) return {};

    final categories = <String, int>{};

    for (var todo in _todoBox!.values) {
      final category = todo.category ?? 'Tanpa Kategori';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return categories;
  }
}