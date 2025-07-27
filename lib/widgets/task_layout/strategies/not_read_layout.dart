import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../../../screens/correction_screen.dart';
import '../../../services/task_provider.dart';
import '../base/base_task_layout_strategy.dart';

// Concrete strategy implementation for not read status
class NotReadLayoutStrategy extends BaseTaskLayoutStrategy {
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
    return [
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
      buildPrimaryButton(
        text: 'Прочитал и понял',
        onPressed: () {
          context
              .read<TaskProvider>()
              .updateTaskStatus(task, TaskStatus.inOrder);
        },
      ),
      buildSecondaryButton(
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

  List<Widget> _buildCommunicatorLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    return [
      buildControlPointsSection(),
      buildPrimaryButton(
        text: 'Напомнить прочитать',
        onPressed: () {},
      ),
      const Divider(),
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildSectionItem(icon: Iconsax.clock_copy, title: 'История задачи'),
      const Divider(),
    ];
  }

  List<Widget> _buildCreatorLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    return [
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
    ];
  }

  List<Widget> _buildNoneRoleLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    return [buildHistorySection(context, revisions)];
  }
}
