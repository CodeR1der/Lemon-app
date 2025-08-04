import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/control_point.dart';
import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../base/base_task_layout_strategy.dart';

// Overdue Layout Strategy
class OverdueLayoutStrategy extends BaseTaskLayoutStrategy {
  @override
  List<Widget> buildSections(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    switch (role) {
      case TaskRole.executor:
        return _buildExecutorLayout(context, task, revisions, controlPoints);
      case TaskRole.communicator:
        return _buildCommunicatorLayout(
            context, task, revisions, controlPoints);
      case TaskRole.creator:
        return _buildCreatorLayout(context, task, revisions, controlPoints);
      case TaskRole.none:
        return _buildNoneRoleLayout(context, task, revisions, controlPoints);
    }
  }

  List<Widget> _buildExecutorLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return [
      buildControlPointsSection(
          context, task, TaskRole.executor, controlPoints),
      if (revisions.isNotEmpty && revisions.any((revision) => !revision.isDone))
        buildRevisionsSection(context, task, TaskRole.executor, revisions),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
    ];
  }

  List<Widget> _buildCommunicatorLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return [
      buildControlPointsSection(
          context, task, TaskRole.communicator, controlPoints),
      const Divider(),
      if (task.status == TaskStatus.overdue &&
          TaskRole.communicator == TaskRole.communicator &&
          revisions.isNotEmpty &&
          revisions.any((revision) =>
              (revision.description ?? '').trim() == 'Просроченная задача' &&
              !revision.isDone))
        buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы')
      else if (revisions.isNotEmpty &&
          revisions.any((revision) => !revision.isDone))
        buildRevisionsSection(context, task, TaskRole.communicator, revisions)
      else
        buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
    ];
  }

  List<Widget> _buildCreatorLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return [
      buildControlPointsSection(context, task, TaskRole.creator, controlPoints),
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
    ];
  }

  List<Widget> _buildNoneRoleLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return [
      buildControlPointsSection(context, task, TaskRole.none, controlPoints),
      buildHistorySection(context, revisions)
    ];
  }
}
