import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../screens/queue_screen.dart';
import '../base/base_task_layout_strategy.dart';

class InOrderLayoutStrategy extends BaseTaskLayoutStrategy {
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
    return [];
  }

  List<Widget> _buildCommunicatorLayout(
      BuildContext context, Task task, List<Correction> revisions) {
    return [
      buildControlPointsSection(),
      const Divider(),
      buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildHistorySection(context, revisions),
      const Divider(),
      buildPrimaryButton(
        text: 'Выставить в очередь',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QueueScreen(task: task)),
          );
        },
      ),
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