import 'package:flutter/cupertino.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

enum TaskStatus {
  newTask, // Новая задача
  revision, // Задача на доработке
  inOrder, // Выставить в очередь
  notRead, // Не прочитано / не понято
  queue, // в очереди на выполнение
  needExplanation, // Нужно разъяснение
  atWork, // В работе
  needTicket, // Нужно письмо-решение
  controlPoint, // Контрольная точка
  extraTime, // Запросы на дополнительное время
  overdue, // Просроченная задача
  completedUnderReview, // Завершенная задача на проверке
  completed // завершенная
}

class StatusHelper {
  static String displayName(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return 'Новая задача';
      case TaskStatus.revision:
        return 'Задача на доработке';
      case TaskStatus.queue:
        return 'В очереди на выполнение';
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
      case TaskStatus.needTicket:
        return 'Нужно письмо-решение';
      case TaskStatus.extraTime:
        return 'Запросы на дополнительное время';
      case TaskStatus.overdue:
        return 'Просроченная задача';
      case TaskStatus.completedUnderReview:
        return 'Завершенная задача на проверке';
      case TaskStatus.completed:
        return 'Архив задач';
    }
  }

  static TaskStatus toTaskStatus(String status) {
    switch (status) {
      case 'Новая задача':
        return TaskStatus.newTask;
      case 'newTask':
        return TaskStatus.newTask;

      case 'Задача на доработке':
        return TaskStatus.revision;
      case 'revision':
        return TaskStatus.revision;

      case 'Выставить в очередь на выполнение':
        return TaskStatus.queue;
      case 'queue':
        return TaskStatus.queue;

      case 'Не прочитано / не понято':
        return TaskStatus.notRead;
      case 'notRead':
        return TaskStatus.notRead;

      case 'Нужно разъяснение':
        return TaskStatus.needExplanation;
      case 'needExplanation':
        return TaskStatus.needExplanation;

      case 'Выставить в очередь':
        return TaskStatus.inOrder;
      case 'inOrder':
        return TaskStatus.inOrder;

      case 'В работе':
        return TaskStatus.atWork;
      case 'atWork':
        return TaskStatus.atWork;

      case 'Контрольная точка':
        return TaskStatus.controlPoint;
      case 'controlPoint':
        return TaskStatus.controlPoint;

      case 'Нужно письмо-решение':
        return TaskStatus.needTicket;
      case 'needTicket':
        return TaskStatus.needTicket;

      case 'Запросы на дополнительное время':
        return TaskStatus.extraTime;
      case 'extraTime':
        return TaskStatus.extraTime;

      case 'Просроченная задача':
        return TaskStatus.overdue;
      case 'overdue':
        return TaskStatus.overdue;

      case 'Завершенная задача на проверке':
        return TaskStatus.completedUnderReview;
      case 'completedUnderReview':
        return TaskStatus.completedUnderReview;

      case 'Архив задач':
        return TaskStatus.completed;
      case 'completed':
        return TaskStatus.completed;

      default:
        throw ArgumentError('Неизвестный статус задачи: $status');
    }
  }

  static IconData getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return Iconsax.d_cube_scan_copy;
      case TaskStatus.revision:
        return Iconsax.box_search_copy;
      case TaskStatus.queue:
        return Iconsax.stickynote_copy;
      case TaskStatus.notRead:
        return Iconsax.eye_copy;
      case TaskStatus.needExplanation:
        return Iconsax.timer_copy;
      case TaskStatus.inOrder:
        return Iconsax.task_square_copy;
      case TaskStatus.atWork:
        return Iconsax.archive_tick_copy;
      case TaskStatus.controlPoint:
        return Iconsax.arrow_square_copy;
      case TaskStatus.needTicket:
        return Iconsax.edit_copy;
      case TaskStatus.extraTime:
        return Iconsax.clock_copy;
      case TaskStatus.overdue:
        return Iconsax.calendar_remove_copy;
      case TaskStatus.completedUnderReview:
        return Iconsax.search_normal_copy;
      case TaskStatus.completed:
        return Iconsax.folder_open_copy;
    }
  }
}
