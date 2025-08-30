import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../models/control_point.dart';
import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../../../screens/corrections/correction_screen.dart';
import '../../../services/task_provider.dart';
import '../../common/app_buttons.dart';
import '../../common/app_spacing.dart';
import '../base/base_task_layout_strategy.dart';

// Concrete strategy implementation for not read status
class NotReadLayoutStrategy extends BaseTaskLayoutStrategy {
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
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
      AppButtons.primaryButton(
        text: 'Прочитал и понял',
        onPressed: () {
          context
              .read<TaskProvider>()
              .updateTaskStatus(task, TaskStatus.inOrder);
        },
      ),
      AppSpacing.height16,
      AppButtons.secondaryButton(
        text: 'Нужно разъяснение',
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
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
    ];
  }

  List<Widget> _buildCreatorLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return [
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
    ];
  }

  List<Widget> _buildNoneRoleLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return [
      buildHistorySection(context, revisions)
    ];
  }
}
