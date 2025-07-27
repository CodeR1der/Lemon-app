import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../screens/task_history.dart';
import '../../../widgets/revision_section.dart';
import '../interfaces/task_layout_strategy.dart';

// Base class for common layout functionality
abstract class BaseTaskLayoutStrategy implements TaskLayoutStrategy {
  @override
  Widget buildLayout(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions) {
    return Column(
      children: buildSections(context, task, role, revisions),
    );
  }

  List<Widget> buildSections(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions);

  // Common widgets
  Widget buildSectionItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: title == 'История задачи' ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF6D7885)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            if (title == 'История задачи')
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildHistorySection(BuildContext context, List<Correction> revisions) {
    return buildSectionItem(
      icon: Iconsax.clock_copy,
      title: 'История задачи',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskHistoryScreen(revisions: revisions),
          ),
        );
      },
    );
  }

  Widget buildRevisionsSection(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions) {
    if (revisions.isNotEmpty && revisions.any((revision) => !revision.isDone)) {
      return RevisionsCard(
        revisions: revisions,
        task: task,
        role: role,
        title: 'Доработки и запросы',
      );
    }
    return buildSectionItem(
        icon: Iconsax.edit_copy, title: 'Доработки и запросы');
  }

  Widget buildControlPointsSection() {
    return buildSectionItem(
        icon: Iconsax.clock_copy, title: 'Контрольные точки');
  }

  Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.orange,
    Color textColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.orange, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
