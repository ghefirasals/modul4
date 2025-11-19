import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 3)
class TodoItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  int priority; // 1: Low, 2: Medium, 3: High

  @HiveField(7)
  String? category;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.priority = 2,
    this.category,
  });

  // Helper methods
  String get priorityText {
    switch (priority) {
      case 1:
        return 'Rendah';
      case 2:
        return 'Sedang';
      case 3:
        return 'Tinggi';
      default:
        return 'Sedang';
    }
  }

  String get statusText {
    return isCompleted ? 'Selesai' : 'Belum';
  }

  // Mark as completed
  void markAsCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
    save();
  }

  // Mark as incomplete
  void markAsIncomplete() {
    isCompleted = false;
    completedAt = null;
    save();
  }

  // Toggle completion status
  void toggleCompletion() {
    if (isCompleted) {
      markAsIncomplete();
    } else {
      markAsCompleted();
    }
  }
}