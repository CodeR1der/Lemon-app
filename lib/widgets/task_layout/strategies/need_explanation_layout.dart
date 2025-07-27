import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_status.dart';
import '../../../services/request_operation.dart';
import '../base/base_task_layout_strategy.dart';

class NeedExplanationLayoutStrategy extends BaseTaskLayoutStrategy {
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
    final notDoneRevision =
        revisions.where((revision) => !revision.isDone).first;
    return [
      buildControlPointsSection(),
      const Divider(),
      if (revisions.isNotEmpty && revisions.any((revision) => !revision.isDone)) ...[
        buildRevisionsSection(context, task, TaskRole.communicator, revisions),
        Column(children: [
          ElevatedButton(
            onPressed: () {
              RequestService().updateCorrection(notDoneRevision..isDone = true);

              RequestService().addCorrection(Correction(
                  date: DateTime.now(),
                  taskId: task.id,
                  status: TaskStatus.needExplanation,
                  description: 'Прислать письмо-решение'));

              task.changeStatus(TaskStatus.needTicket);

              print('Жалоба на некорректную постановку задачи');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 8),
                Text(
                  'Прислать письмо-решение',
                  style: TextStyle(
                    color: Colors.white, // Белый текст
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              RequestService().updateCorrection(notDoneRevision..isDone = true);
              task.changeStatus(TaskStatus.revision);
              print('Жалоба на некорректную постановку задачи');
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.orange, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 8),
                Text(
                  'Отправить на доработку',
                  style: TextStyle(
                    color: Colors.black, // Белый текст
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ]
      else
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
