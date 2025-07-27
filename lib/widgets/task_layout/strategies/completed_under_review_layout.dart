import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../models/task_validate.dart';
import '../../../screens/task_validate_details_screen.dart';
import '../../../services/request_operation.dart';
import '../base/base_task_layout_strategy.dart';

// Completed Under Review Layout Strategy
class CompletedUnderReviewLayoutStrategy extends BaseTaskLayoutStrategy {
  @override
  Widget buildLayout(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions) {
    return FutureBuilder<TaskValidate?>(
      future: RequestService().getValidate(task.id, task.status),
      builder: (context, validateSnapshot) {
        if (validateSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final validate = validateSnapshot.data;

        switch (role) {
          case TaskRole.executor:
            return Column(
              children: [
                buildSectionItem(
                    icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                buildHistorySection(context, revisions),
                const Divider(),
              ],
            );
          case TaskRole.communicator:
            return Column(
              children: [
                buildControlPointsSection(),
                const Divider(),
                buildSectionItem(
                    icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                buildHistorySection(context, revisions),
              ],
            );
          case TaskRole.creator:
            return Column(
              children: [
                buildSectionItem(
                    icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                buildHistorySection(context, revisions),
                const Divider(),
                buildSecondaryButton(
                  text: 'Проверить задачу',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskValidateDetailsScreen(
                            task: task, validate: validate!),
                      ),
                    );
                  },
                ),
              ],
            );
          case TaskRole.none:
            throw UnimplementedError();
        }
      },
    );
  }

  @override
  List<Widget> buildSections(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions) {
    // This method is not used for this strategy since we override buildLayout
    return [];
  }
}