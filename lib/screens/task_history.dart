import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker/models/correction.dart';

import '../models/task_status.dart';

class TaskHistoryScreen extends StatelessWidget {
  final List<Correction> revisions;

  TaskHistoryScreen({super.key, required this.revisions});

  @override
  Widget build(BuildContext context) {
    revisions.sort((x, y) => x.date.compareTo(y.date));
    return Scaffold(
      appBar: AppBar(
        title: const Text('История задачи'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...revisions
                .map((revision) => _buildRevisionItem(context, revision))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionItem(BuildContext context, Correction correction) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Дата создания
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(correction.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                  ),
            ),
            const SizedBox(height: 4),
            if (correction.status != TaskStatus.needExplanation)
              Text(
                _getActionTitle(correction.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            const SizedBox(height: 4),
            // Описание доработки
            Text(
              correction.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionTitle(TaskStatus status) {
    switch (status) {
      case TaskStatus.atWork:
        return 'Запрос на дополнительное время';
      case TaskStatus.newTask:
        return 'Описание ошибок в поставке задачи';
      case TaskStatus.notRead:
        return 'Причина разъяснения';
      case TaskStatus.needTicket:
        return 'Письмо-решение';
      // Добавьте другие статусы по необходимости
      default:
        return 'Изменение статуса';
    }
  }
}
