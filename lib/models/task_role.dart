import 'package:task_tracker/models/task.dart';

enum TaskRole {
  communicator, // Коммуникатор
  creator, // Постановщик
  executor, // Исполнитель (в команде)
  none // Не имеет отношения к задаче
}

class RoleHelper {

  static String convertToString(TaskRole role) {
    switch (role) {
      case TaskRole.communicator:
        return 'Коммуникатор';
      case TaskRole.creator:
        return 'Постановщик';
      case TaskRole.executor:
        return 'Исполнитель';
      case TaskRole.none:
        return 'Не имеет отношения к задаче';
    }
  }
  static TaskRole determineUserRoleInTask({
    required String currentUserId,
    required Task task,
  }) {
    // Проверяем, является ли пользователь коммуникатором
    if (task.team.communicatorId.userId == currentUserId) {
      return TaskRole.communicator;
    }

    // Проверяем, является ли пользователь постановщиком
    if (task.team.creatorId.userId == currentUserId) {
      return TaskRole.creator;
    }

    // Проверяем, является ли пользователь исполнителем (в команде)
    final isExecutor =
        task.team.teamMembers.any((member) => member.userId == currentUserId);
    if (isExecutor) {
      return TaskRole.executor;
    }

    // Если не подходит ни под одну роль
    return TaskRole.none;
  }
}
