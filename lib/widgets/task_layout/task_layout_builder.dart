import 'package:flutter/material.dart';

import '../../models/correction.dart';
import '../../models/task.dart';
import '../../models/task_role.dart';
import '../../services/request_operation.dart';
import 'factory/task_layout_factory.dart';

// Main widget that uses the strategy pattern
class TaskLayoutBuilder extends StatelessWidget {
  final Task task;
  final TaskRole role;

  const TaskLayoutBuilder({
    super.key,
    required this.task,
    required this.role,
  });

  Future<List<Correction>> _loadCorrections() {
    return RequestService().getCorrection(task.id, task.status);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Correction>>(
      future: _loadCorrections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final revisions = snapshot.data ?? [];
        final strategy = TaskLayoutFactory.getStrategy(task.status);

        return strategy.buildLayout(context, task, role, revisions);
      },
    );
  }
}
