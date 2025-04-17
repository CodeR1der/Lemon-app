import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Import the intl package

import '../models/task.dart';

class TaskPeriodTab extends StatelessWidget {
  final Task task;

  TaskPeriodTab({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    // Format the date to display only the date part (e.g., "12.12.2024")
    String formattedDate = DateFormat('dd.MM.yyyy').format(task.endDate);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Период выполнения:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Text(formattedDate),  // Use the formatted date string
          const SizedBox(height: 16.0),
          const Text('Приоритет:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Text(task.priorityToString()),
        ],
      ),
    );
  }
}
