import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 3)
class TodoItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  int priority; // 1-5, 5 = highest priority

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? dueDate;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  DateTime? completedAt;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = 3,
    DateTime? createdAt,
    this.dueDate,
    this.tags = const [],
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    List<String>? tags,
    DateTime? completedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  void toggleCompleted() {
    isCompleted = !isCompleted;
    if (isCompleted) {
      completedAt = DateTime.now();
    } else {
      completedAt = null;
    }
    save();
  }

  void updateTitle(String newTitle) {
    title = newTitle;
    save();
  }

  void updateDescription(String newDescription) {
    description = newDescription;
    save();
  }

  void updatePriority(int newPriority) {
    priority = newPriority.clamp(1, 5);
    save();
  }

  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      save();
    }
  }

  void removeTag(String tag) {
    tags.remove(tag);
    save();
  }

  String get priorityText {
    switch (priority) {
      case 5:
        return '🔴 Urgent';
      case 4:
        return '🟠 High';
      case 3:
        return '🟡 Medium';
      case 2:
        return '🟢 Low';
      case 1:
        return '⚪ Very Low';
      default:
        return '🟡 Medium';
    }
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueDateOnly.isAtSameMomentAs(today);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'tags': tags,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      description: json['description'],
      isCompleted: json['is_completed'] ?? false,
      priority: json['priority'] ?? 3,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  @override
  String toString() {
    return 'TodoItem(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority)';
  }
}