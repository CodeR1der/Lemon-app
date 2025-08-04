import 'package:flutter/material.dart';

import '../../models/control_point.dart';
import '../../models/correction.dart';
import '../../models/task.dart';
import '../../models/task_role.dart';
import '../../services/control_point_operations.dart';
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

  Future<List<ControlPoint>> _loadControlPoints() {
    return ControlPointService().getControlPointsForTask(task.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Correction>>(
      future: _loadCorrections(),
      builder: (context, correctionsSnapshot) {
        if (correctionsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (correctionsSnapshot.hasError) {
          return Center(child: Text('Ошибка: ${correctionsSnapshot.error}'));
        }

        final revisions = correctionsSnapshot.data ?? [];

        return FutureBuilder<List<ControlPoint>>(
          future: _loadControlPoints(),
          builder: (context, controlPointsSnapshot) {
            if (controlPointsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controlPointsSnapshot.hasError) {
              return Center(
                  child: Text('Ошибка: ${controlPointsSnapshot.error}'));
            }

            final controlPoints = controlPointsSnapshot.data ?? [];
            final strategy = TaskLayoutFactory.getStrategy(task.status);

            return strategy.buildLayout(
                context, task, role, revisions, controlPoints);
          },
        );
      },
    );
  }
}
