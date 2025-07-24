import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskPeriodTab extends StatelessWidget {
  final Task task;

  const TaskPeriodTab({super.key, required this.task});
  String _formatDeadline(DateTime? dateTime) {
    if (dateTime == null) return 'Не установлен';
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dateTime)}, до ${timeFormat.format(dateTime)}';
  }
  @override
  Widget build(BuildContext context) {
    final String formattedDate;
    if(task.deadline == null)
      {
        formattedDate = DateFormat('dd.MM.yyyy').format(task.endDate);
      }
    else{
      formattedDate = _formatDeadline(task.deadline);
    }

    final priorityText = task.priorityToString();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
              context: context,
              title: 'Срок выполнения:',
              value: formattedDate,
              icon: Iconsax.calendar_2,
              iconColor: Colors.grey),
          const SizedBox(height: 24),
          _buildInfoRow(
            context: context,
            title: 'Приоритет:',
            value: priorityText,
            icon: Iconsax.flash_1,
            iconColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor, // Параметр для цвета иконки
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ??
                  const Color(
                      0xFF049FFF), // Используем переданный цвет или синий по умолчанию
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
