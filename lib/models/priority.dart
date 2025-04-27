enum Priority { low, medium, high }

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Низкий';
      case Priority.medium:
        return 'Средний';
      case Priority.high:
        return 'Высокий';
    }
  }
}