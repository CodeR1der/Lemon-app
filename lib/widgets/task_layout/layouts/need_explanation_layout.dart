import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';

import '../../../models/control_point.dart';
import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../../../services/request_operation.dart';
import '../base/base_task_layout_strategy.dart';

class NeedExplanationLayoutStrategy extends BaseTaskLayoutStrategy {
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
    return [];
  }

  List<Widget> _buildCommunicatorLayout(BuildContext context, Task task,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    final notDoneRevision =
        revisions.where((revision) => !revision.isDone).first;
    return [
      buildControlPointsSection(
          context, task, TaskRole.communicator, controlPoints),
      const Divider(),
      if (revisions.isNotEmpty &&
          revisions.any((revision) => !revision.isDone)) ...[
        buildRevisionsSection(context, task, TaskRole.communicator, revisions),
        Column(children: [
          AppButtons.primaryButton(
              text: 'Прислать письмо-решение',
              onPressed: () {
                RequestService()
                    .updateCorrection(notDoneRevision..isDone = true);

                RequestService().addCorrection(Correction(
                    date: DateTime.now(),
                    taskId: task.id,
                    status: TaskStatus.needExplanation,
                    description: 'Прислать письмо-решение'));

                task.changeStatus(TaskStatus.needTicket);

                print('Жалоба на некорректную постановку задачи');
              }),
          const SizedBox(height: 16),
          AppButtons.secondaryButton(
            onPressed: () {
              //RequestService().updateCorrection(notDoneRevision..isDone = true);
              task.changeStatus(TaskStatus.revision);
              print('Жалоба на некорректную постановку задачи');
            },
            text: 'Отправить на доработку',
          ),
        ]),
      ] else
        buildSectionItem(icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
      const Divider(),
      buildSectionItem(icon: Iconsax.clock_copy, title: 'История задачи'),
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
    return [buildHistorySection(context, revisions)];
  }
}
