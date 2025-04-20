enum TaskStatus {
  newTask, // Новая задача
  revision, // Задача на доработке
  notRead, // Не прочитано / не понято
  needExplanation, // Нужно разъяснение
  inOrder, // Выставить в очередь
  atWork, // В работе
  controlPoint, // Контрольная точка
  extraTime, // Запросы на дополнительное время
  overdue, // Просроченная задача
  completedUnderReview // Завершенная задача на проверке
}

// Метод для преобразования enum в читаемый текст
extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.newTask:
        return 'Новая задача';
      case TaskStatus.revision:
        return 'Задача на доработке';
      case TaskStatus.notRead:
        return 'Не прочитано / не понято';
      case TaskStatus.needExplanation:
        return 'Нужно разъяснение';
      case TaskStatus.inOrder:
        return 'Выставить в очередь';
      case TaskStatus.atWork:
        return 'В работе';
      case TaskStatus.controlPoint:
        return 'Контрольная точка';
      case TaskStatus.extraTime:
        return 'Запросы на дополнительное время';
      case TaskStatus.overdue:
        return 'Просроченная задача';
      case TaskStatus.completedUnderReview:
        return 'Завершенная задача на проверке';
    }
  }
}