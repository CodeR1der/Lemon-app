import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/control_point.dart';
import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../../../screens/correction_screen.dart';
import '../../../screens/task_validate_screen.dart';
import '../base/base_task_layout_strategy.dart';

class AtWorkLayoutStrategy extends BaseTaskLayoutStrategy {
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
    final notDoneRevisions = revisions.where((r) => !r.isDone).firstOrNull;

    return [
      buildControlPointsSection(
          context, task, TaskRole.executor, controlPoints),
      if (notDoneRevisions != null &&
          notDoneRevisions.status == TaskStatus.completedUnderReview)
        buildRevisionsSection(context, task, TaskRole.executor, revisions)
      else
        buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
      const SizedBox(height: 12),
      buildPrimaryButton(
        text: 'Сдать задачу на проверку',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TaskValidateScreen(task: task)),
          );
        },
      ),
      const SizedBox(height: 16),
      buildSecondaryButton(
        text: 'Запросить дополнительное время',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CorrectionScreen(task: task)),
          );
        },
      ),
    ];
  }

  List<Widget> _buildCommunicatorLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return [
      buildControlPointsSection(
          context, task, TaskRole.communicator, controlPoints),
      const Divider(),
      if (revisions.isNotEmpty && revisions.any((revision) => !revision.isDone))
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
