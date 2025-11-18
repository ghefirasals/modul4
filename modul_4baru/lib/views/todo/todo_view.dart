import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/todo_service.dart';
import '../../models/todo_item.dart';

class TodoView extends StatefulWidget {
  const TodoView({super.key});

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  late TodoService _todoService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _todoService = Get.find<TodoService>();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: '',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _clearCompletedTodos,
            tooltip: 'Clear Completed',
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
                hintText: 'Search todos...',
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

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              final stats = _todoService.getStatistics();
              return Wrap(
                spacing: 8,
                children: [
                  _buildStatChip('Total', stats['total']!, Get.theme.colorScheme.primary),
                  _buildStatChip('Active', stats['incomplete']!, Colors.orange),
                  _buildStatChip('Completed', stats['completed']!, Colors.green),
                ],
              );
            }),
          ),

          const SizedBox(height: 16),

          // Todo list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(() => _todoService.todos),
                _buildTodoList(() => _todoService.incompleteTodos),
                _buildTodoList(() => _todoService.completedTodos),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTodoList(List<TodoItem> Function() getTodos) {
    return Obx(() {
      final todos = getTodos();
      final filteredTodos = _searchQuery.value.isEmpty
          ? todos
          : _todoService.searchTodos(_searchQuery.value);

      if (filteredTodos.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Get.theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No todos found',
                style: Get.theme.textTheme.titleMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.value.isEmpty
                    ? 'Tap the + button to add a new todo'
                    : 'Try a different search term',
                style: Get.theme.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          final todo = filteredTodos[index];
          return _buildTodoTile(todo);
        },
      );
    });
  }

  Widget _buildTodoTile(TodoItem todo) {
    return Dismissible(
      key: Key(todo.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _todoService.deleteTodo(todo.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: todo.isCompleted,
            onChanged: (value) {
              _todoService.toggleTodoCompletion(todo.id);
            },
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted
                  ? Get.theme.colorScheme.onSurface.withOpacity(0.6)
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.description != null && todo.description!.isNotEmpty)
                Text(
                  todo.description!,
                  style: TextStyle(
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (todo.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: todo.isOverdue
                              ? Colors.red
                              : Get.theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(todo.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: todo.isOverdue
                                ? Colors.red
                                : Get.theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  Text(
                    todo.priorityText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (todo.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: todo.tags.map((tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditTodoDialog(todo);
                  break;
                case 'delete':
                  _todoService.deleteTodo(todo.id);
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
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTodoDialog() {
    _showTodoDialog();
  }

  void _showEditTodoDialog(TodoItem todo) {
    _showTodoDialog(todo: todo);
  }

  void _showTodoDialog({TodoItem? todo}) {
    final titleController = TextEditingController(text: todo?.title);
    final descriptionController = TextEditingController(text: todo?.description);
    int priority = todo?.priority ?? 3;
    DateTime? dueDate = todo?.dueDate;
    final tagsController = TextEditingController(text: todo?.tags.join(', ') ?? '');

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(todo == null ? 'Add Todo' : 'Edit Todo'),
            content: SingleChildScrollView(
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
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('⚪ Very Low')),
                      DropdownMenuItem(value: 2, child: Text('🟢 Low')),
                      DropdownMenuItem(value: 3, child: Text('🟡 Medium')),
                      DropdownMenuItem(value: 4, child: Text('🟠 High')),
                      DropdownMenuItem(value: 5, child: Text('🔴 Urgent')),
                    ],
                    onChanged: (value) => setState(() => priority = value ?? 3),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      dueDate != null ? _formatDate(dueDate!) : 'No Due Date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => dueDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      border: OutlineInputBorder(),
                      hintText: 'work, personal, urgent',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: titleController.text.trim().isEmpty
                    ? null
                    : () {
                        final tags = tagsController.text
                            .split(',')
                            .map((tag) => tag.trim())
                            .where((tag) => tag.isNotEmpty)
                            .toList();

                        if (todo == null) {
                          _todoService.addTodo(
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            priority: priority,
                            dueDate: dueDate,
                            tags: tags,
                          );
                        } else {
                          final updatedTodo = todo.copyWith(
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            priority: priority,
                            dueDate: dueDate,
                            tags: tags,
                          );
                          _todoService.updateTodo(updatedTodo);
                        }
                        Get.back();
                      },
                child: Text(todo == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _clearCompletedTodos() {
    if (_todoService.completedTodos.isEmpty) {
      Get.snackbar(
        'Info',
        'No completed todos to clear',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Clear Completed Todos'),
        content: Text(
          'Are you sure you want to delete ${_todoService.completedTodos.length} completed todos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _todoService.deleteCompletedTodos();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dateOnly.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (dateOnly.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}