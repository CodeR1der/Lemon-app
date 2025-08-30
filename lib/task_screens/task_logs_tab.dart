import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/widgets/common/app_common.dart';

class TaskLogsTab extends StatefulWidget {
  final Task task;

  const TaskLogsTab({super.key, required this.task});

  @override
  State<TaskLogsTab> createState() => _TaskLogsTabState();
}

class _TaskLogsTabState extends State<TaskLogsTab> {
  List<TaskLog> _logs = [];
  bool _isLoading = true;
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _taskService.getTaskLogs(widget.task.id);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Ошибка', 'Не удалось загрузить логи');
    }
  }

  String _getActionText(TaskLog log) {
    switch (log.action) {
      case 'created':
        return 'Создал задачу';
      case 'status_changed':
        return 'Сменил статус';
      case 'assigned':
        return 'Назначил исполнителя';
      case 'completed':
        return 'Завершил задачу';
      case 'reopened':
        return 'Переоткрыл задачу';
      case 'deadline_changed':
        return 'Изменил дедлайн';
      case 'priority_changed':
        return 'Изменил приоритет';
      case 'closed':
        return 'Закрыл задачу';
      default:
        return 'Выполнил действие';
    }
  }

  String _getEntityText(TaskLog log) {
    switch (log.action) {
      case 'status_changed':
        if (log.newValue == 'completed') {
          return 'Завершил задачу';
        } else if (log.newValue == 'closed') {
          return 'Закрыл задачу';
        } else {
          return 'Изменил статус на ${log.newValue ?? 'новый'}';
        }
      case 'assigned':
        return 'Назначил ${log.targetUserName ?? 'исполнителя'}';
      case 'deadline_changed':
        return 'Установил дедлайн ${log.newValue ?? ''}';
      case 'priority_changed':
        return 'Установил приоритет ${log.newValue ?? ''}';
      default:
        return '';
    }
  }

  IconData _getActionIcon(TaskLog log) {
    switch (log.action) {
      case 'created':
        return Icons.add;
      case 'status_changed':
        return Icons.swap_horiz;
      case 'assigned':
        return Icons.person_add;
      case 'completed':
        return Icons.check_circle;
      case 'reopened':
        return Icons.refresh;
      case 'deadline_changed':
        return Icons.schedule;
      case 'priority_changed':
        return Icons.priority_high;
      case 'closed':
        return Icons.close;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(TaskLog log) {
    switch (log.action) {
      case 'created':
        return Colors.green;
      case 'status_changed':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'reopened':
        return Colors.amber;
      case 'deadline_changed':
        return Colors.purple;
      case 'priority_changed':
        return Colors.red;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'Логи отсутствуют',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];

        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Дата измнения', style: AppTextStyles.titleSmall,),
              // Дата изменения с иконкой календаря
              Row(
                children: [
                  Icon(
                    Iconsax.calendar,//
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${log.timestamp.day.toString().padLeft(2, '0')}.${log.timestamp.month.toString().padLeft(2, '0')}.${log.timestamp.year}, ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodyMedium
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Пользователь
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пользователь',
                    style: AppTextStyles.titleSmall
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.userName,
                    style: AppTextStyles.bodyMedium
                  ),
                  Text(
                    log.userRole,
                    style: AppTextStyles.caption
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Тип действия
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Тип действия',
                    style: AppTextStyles.titleSmall
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getActionText(log),
                    style: AppTextStyles.bodyMedium
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Сущность
              if (_getEntityText(log).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сущность',
                      style: AppTextStyles.titleSmall
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getEntityText(log),
                      style: AppTextStyles.bodyMedium
                    ),
                  ],
                ),
              const Divider()
            ],
          ),
        );
      },
    );
  }
}
