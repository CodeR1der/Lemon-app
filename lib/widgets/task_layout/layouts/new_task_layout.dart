import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';

import '../../../models/control_point.dart';
import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../../../screens/corrections/correction_screen.dart';
import '../../../services/task_provider.dart';
import '../base/base_task_layout_strategy.dart';

// Concrete strategy implementation for new task status
class NewTaskLayoutStrategy extends BaseTaskLayoutStrategy {
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
      else ...[
        buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
        AppButtons.primaryButton(
          text: 'Задача поставлена плохо / некорректно',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CorrectionScreen(task: task)),
            );
          },
        ),
      ],
      const Divider(),
      buildHistorySection(context, revisions),
      Consumer<TaskProvider>(
        builder: (context, taskProvider, child) => buildPrimaryButton(
          text: 'Выставить в очередь на выполнение',
          backgroundColor: Colors.white,
          textColor: Colors.black,
          onPressed: () {
            taskProvider.updateTaskStatus(task, TaskStatus.notRead);
          },
        ),
      ),
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
