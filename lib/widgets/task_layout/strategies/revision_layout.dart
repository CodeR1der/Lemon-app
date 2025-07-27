import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../base/base_task_layout_strategy.dart';

// Concrete strategy implementation for revision status
class RevisionLayoutStrategy extends BaseTaskLayoutStrategy {
  @override
  List<Widget> buildSections(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions) {
    switch (role) {
      case TaskRole.executor:
        return _buildExecutorLayout(context, task, revisions);
      case TaskRole.communicator:
        return _buildCommunicatorLayout(context, task, revisions);
      case TaskRole.creator:
        return _buildCreatorLayout(context, task, revisions);
      case TaskRole.none:
        return _buildNoneRoleLayout(context, task, revisions);
    }
  }

  List<Widget> _buildExecutorLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    return _buildCommunicatorLayout(context, task, revisions);
  }

  List<Widget> _buildCommunicatorLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    final notDoneRevision =
        revisions.where((revision) => !revision.isDone).firstOrNull;

    return [
      buildControlPointsSection(),
      const Divider(),
      if (notDoneRevision?.status != TaskStatus.newTask)
        buildRevisionsSection(context, task, TaskRole.communicator, revisions)
      else
        buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
    ];
  }

  List<Widget> _buildCreatorLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    return [
      buildRevisionsSection(context, task, TaskRole.creator, revisions),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
    ];
  }

  List<Widget> _buildNoneRoleLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    return [
      buildHistorySection(context, revisions),
      const Divider(),
      buildRevisionsSection(context, task, TaskRole.none, revisions),
    ];
  }
}
