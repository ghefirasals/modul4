import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/todo_service.dart';
import '../models/todo_item.dart';

class TodoView extends StatelessWidget {
  const TodoView({super.key});

  @override
  Widget build(BuildContext context) {
    final todoService = Get.find<TodoService>();
    
    return TodoViewContent(todoService: todoService);
  }
}

class TodoViewContent extends StatefulWidget {
  final TodoService todoService;
  
  const TodoViewContent({super.key, required this.todoService});

  @override
  State<TodoViewContent> createState() => _TodoViewContentState();
}

class _TodoViewContentState extends State<TodoViewContent> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _selectedPriority = 2;
  String _selectedCategory = '';

  TodoService get todoService => widget.todoService;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          _buildStatisticsSection(),
          Expanded(
            child: Obx(() {
              final filteredTodos = todoService.filteredTodos;

              if (filteredTodos.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTodos.length,
                itemBuilder: (context, index) {
                  final todo = filteredTodos[index];
                  return TodoCard(
                    key: ValueKey(todo.id),
                    todo: todo,
                    onToggle: () => todoService.toggleTodoCompletion(todo.id),
                    onEdit: () => _showEditDialog(todo),
                    onDelete: () => _showDeleteConfirmation(todo),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('📝 Todo List'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'clear_completed':
                _showClearCompletedConfirmation();
                break;
              case 'clear_all':
                _showClearAllConfirmation();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_completed',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 8),
                  Text('Hapus Selesai'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari todo...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),

          const SizedBox(height: 12),

          // Filter chips - DIPERBAIKI: Mutual exclusive
          Row(
            children: [
              Expanded(
                child: Obx(() => FilterChip(
                  label: const Text('Semua'),
                  selected: todoService.selectedStatus.value == 'Semua',
                  onSelected: (_) {
                    todoService.setStatusFilter('Semua');
                  },
                )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => FilterChip(
                  label: const Text('Selesai'),
                  selected: todoService.selectedStatus.value == 'Selesai',
                  onSelected: (_) {
                    if (todoService.selectedStatus.value == 'Selesai') {
                      todoService.setStatusFilter('Semua');
                    } else {
                      todoService.setStatusFilter('Selesai');
                    }
                  },
                )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => FilterChip(
                  label: const Text('Belum'),
                  selected: todoService.selectedStatus.value == 'Belum Selesai',
                  onSelected: (_) {
                    if (todoService.selectedStatus.value == 'Belum Selesai') {
                      todoService.setStatusFilter('Semua');
                    } else {
                      todoService.setStatusFilter('Belum Selesai');
                    }
                  },
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Total',
              value: '${todoService.todos.length}',
              color: Colors.blue,
              icon: Icons.list_alt,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              title: 'Selesai',
              value: '${todoService.completedCount}',
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              title: 'Belum',
              value: '${todoService.pendingCount}',
              color: Colors.orange,
              icon: Icons.pending,
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada todo',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambah todo baru',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => TodoDialog(
        title: 'Tambah Todo',
        titleController: _titleController,
        descriptionController: _descriptionController,
        selectedPriority: _selectedPriority,
        selectedCategory: _selectedCategory,
        availableCategories: todoService.availableCategories,
        onPriorityChanged: (value) => setState(() => _selectedPriority = value),
        onCategoryChanged: (value) => setState(() => _selectedCategory = value),
        onSave: () => _addTodo(),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showEditDialog(TodoItem todo) {
    _titleController.text = todo.title;
    _descriptionController.text = todo.description ?? '';
    _selectedPriority = todo.priority;
    _selectedCategory = todo.category ?? '';

    showDialog(
      context: context,
      builder: (context) => TodoDialog(
        title: 'Edit Todo',
        titleController: _titleController,
        descriptionController: _descriptionController,
        selectedPriority: _selectedPriority,
        selectedCategory: _selectedCategory,
        availableCategories: todoService.availableCategories,
        onPriorityChanged: (value) => setState(() => _selectedPriority = value),
        onCategoryChanged: (value) => setState(() => _selectedCategory = value),
        onSave: () => _updateTodo(todo),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showDeleteConfirmation(TodoItem todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Todo'),
        content: Text('Apakah Anda yakin ingin menghapus "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              todoService.deleteTodo(todo.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showClearCompletedConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Todo Selesai'),
        content: const Text('Apakah Anda yakin ingin menghapus semua todo yang sudah selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              todoService.clearCompletedTodos();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Todo'),
        content: const Text('Apakah Anda yakin ingin menghapus semua todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              todoService.clearAllTodos();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedPriority = 2;
    _selectedCategory = '';
  }

  void _addTodo() {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar(
        '⚠️ Error',
        'Judul tidak boleh kosong',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    todoService.addTodo(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      category: _selectedCategory.trim().isEmpty
          ? null
          : _selectedCategory.trim(),
    );

    Navigator.pop(context);
    _clearForm();
  }

  void _updateTodo(TodoItem todo) {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar(
        '⚠️ Error',
        'Judul tidak boleh kosong',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    todo.title = _titleController.text.trim();
    todo.description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    todo.priority = _selectedPriority;
    todo.category = _selectedCategory.trim().isEmpty
        ? null
        : _selectedCategory.trim();

    todoService.updateTodo(todo);
    Navigator.pop(context);
    _clearForm();
  }
}

class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: todo.isCompleted,
              onChanged: (_) => onToggle(),
              activeColor: Theme.of(context).primaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: todo.isCompleted
                          ? Colors.grey
                          : null,
                    ),
                  ),
                  if (todo.description != null && todo.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      todo.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: todo.isCompleted
                            ? Colors.grey
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(todo.priority),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          todo.priorityText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (todo.category != null && todo.category!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            todo.category!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _formatDate(todo.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
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
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class TodoDialog extends StatefulWidget {
  final String title;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final int selectedPriority;
  final String selectedCategory;
  final List<String> availableCategories;
  final Function(int) onPriorityChanged;
  final Function(String) onCategoryChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const TodoDialog({
    super.key,
    required this.title,
    required this.titleController,
    required this.descriptionController,
    required this.selectedPriority,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<TodoDialog> {
  final TextEditingController _newCategoryController = TextEditingController();
  bool _showNewCategoryField = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Todo',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const Text('Prioritas:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('Rendah', style: TextStyle(fontSize: 12)),
                    value: 1,
                    groupValue: widget.selectedPriority,
                    onChanged: (value) => widget.onPriorityChanged(value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('Sedang', style: TextStyle(fontSize: 12)),
                    value: 2,
                    groupValue: widget.selectedPriority,
                    onChanged: (value) => widget.onPriorityChanged(value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('Tinggi', style: TextStyle(fontSize: 12)),
                    value: 3,
                    groupValue: widget.selectedPriority,
                    onChanged: (value) => widget.onPriorityChanged(value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Kategori:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _showNewCategoryField = !_showNewCategoryField),
                  icon: Icon(_showNewCategoryField ? Icons.remove : Icons.add),
                  label: Text(_showNewCategoryField ? 'Batal' : 'Baru'),
                ),
              ],
            ),
            if (_showNewCategoryField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _newCategoryController,
                decoration: InputDecoration(
                  labelText: 'Kategori baru',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_newCategoryController.text.trim().isNotEmpty) {
                        widget.onCategoryChanged(_newCategoryController.text.trim());
                        _newCategoryController.clear();
                        setState(() => _showNewCategoryField = false);
                      }
                    },
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ] else ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: widget.selectedCategory.isEmpty ? null : widget.selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Pilih Kategori',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tanpa Kategori')),
                  ...widget.availableCategories.map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  ),
                ],
                onChanged: (value) => widget.onCategoryChanged(value ?? ''),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: widget.onSave,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}