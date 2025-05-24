import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/screens/correction_screen.dart';

import '../models/task.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';

class TaskLayoutBuilder extends StatelessWidget {
  final Task task;
  final TaskRole role;

  const TaskLayoutBuilder({
    super.key,
    required this.task,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    switch (task.status) {
      case TaskStatus.newTask:
        return _buildNewTaskLayout(context);
      case TaskStatus.revision:
        return _buildRevisionLayout(context);
      case TaskStatus.inOrder:
        return _buildInOrderLayout(context);
      case TaskStatus.atWork:
        return _buildAtWorkLayout(context);
      case TaskStatus.overdue:
        return _buildOverdueLayout(context);
      case TaskStatus.completed:
        return _buildCompletedLayout(context);
      // Добавьте другие статусы по аналогии
      default:
        return _buildNewTaskLayout(context);
    }
  }

  Widget _buildNewTaskLayout(BuildContext context) {
    switch (role) {
      case TaskRole.executor:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TaskRole.communicator:
        return Column(children: [
          _buildSectionItem(
              icon: Iconsax.clock_copy, title: 'Контрольные точки'),
          const Divider(),
          _buildSectionItem(
              icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CorrectionScreen(task: task),
                  ),
                );
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
                    'Задача поставлена плохо / некорректно',
                    style: TextStyle(
                      color: Colors.white, // Белый текст
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          _buildSectionItem(icon: Iconsax.clock_copy, title: 'История задачи'),
          const Divider(),
        ]);
      case TaskRole.creator:
        // TODO: Handle this case.
        throw UnimplementedError();
      case TaskRole.none:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Widget _buildRevisionLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context),
    );
  }

  Widget _buildInOrderLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context),
    );
  }

  Widget _buildAtWorkLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context),
    );
  }

  Widget _buildOverdueLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context, warning: true),
    );
  }

  Widget _buildCompletedLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context),
    );
  }

  Widget _buildCommonLayout(BuildContext context, {bool warning = false}) {
    return Column(
      children: [
        if (warning)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.withOpacity(0.2),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Срочно! Требуется ваше внимание!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        // Здесь будет ваш основной контент
      ],
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Color(0xFF6D7885)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            if (title == 'История задачи')
              Icon(
                Icons.chevron_right,
                size: 24,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }
}
