import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/control_point.dart';
import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../../../screens/task/add_control_point_screen.dart';
import '../../../screens/task/task_history.dart';
import '../../../services/control_point_operations.dart';
import '../../../widgets/revision_section.dart';
import '../interfaces/task_layout_strategy.dart';

// Base class for common layout functionality
abstract class BaseTaskLayoutStrategy implements TaskLayoutStrategy {
  @override
  Widget buildLayout(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return Column(
      children: buildSections(context, task, role, revisions, controlPoints),
    );
  }

  List<Widget> buildSections(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions, List<ControlPoint> controlPoints);

  // Common widgets
  Widget buildSectionItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
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

  Widget buildControlPointsSection(BuildContext context, Task task,
      TaskRole role, List<ControlPoint> controlPoints) {
    if (controlPoints.isEmpty) {
      return Column(
        children: [
          Row(
            children: [
              const Icon(Iconsax.clock_copy,
                  size: 24, color: Color(0xFF6D7885)),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Контрольные точки',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              if (role == TaskRole.communicator) ...[
                IconButton(
                  onPressed: () => _addControlPoint(context, task),
                  icon: const Icon(Icons.add, color: Colors.orange),
                  iconSize: 20,
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        // Заголовок секции
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Icon(Iconsax.clock_copy, size: 24, color: Color(0xFF6D7885)),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Контрольные точки',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Список контрольных точек
        ...controlPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final controlPoint = entry.value;

          return Column(
            children: [
              _buildControlPointItem(controlPoint, role),
              if (index < controlPoints.length - 1) const Divider(height: 1),
            ],
          );
        }),
        // Кнопки для коммуникатора
        if (role == TaskRole.communicator && controlPoints.isNotEmpty) ...[
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  AppButtons.primaryButton(
                    onPressed: () => _showCheckProgressMenu(context, task),
                    text: 'Проверить ход работы',
                    icon: Icons.phone,
                  ),
                  AppSpacing.height16,
                  AppButtons.secondaryButton(
                    onPressed: () => _addControlPoint(context, task),
                    text: 'Добавить контрольную точку',
                    icon: Icons.add,
                  ),
                ],
              )
          )
        ],
      ],
    );
  }

  Widget _buildControlPointItem(ControlPoint controlPoint, TaskRole role) {
    final isOverdue =
        !controlPoint.isCompleted && controlPoint.date.isBefore(DateTime.now());

    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.calendar,
                        size: 16,
                        color: Color(0xff47475A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${controlPoint.date.day}.${controlPoint.date.month}.${controlPoint.date.year}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (role == TaskRole.communicator)
              InkWell(
                onTap: () => _toggleControlPointStatus(context, controlPoint),
                child: Icon(
                  controlPoint.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 24,
                  color: controlPoint.isCompleted
                      ? Colors.green
                      : (isOverdue ? Colors.red : Colors.grey),
                ),
              )
            else
              Icon(
                controlPoint.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 24,
                color: controlPoint.isCompleted
                    ? Colors.green
                    : (isOverdue ? Colors.red : Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  void _addControlPoint(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddControlPointScreen(task: task),
      ),
    );
  }

  void _toggleControlPointStatus(
      BuildContext context, ControlPoint controlPoint) async {
    try {
      if (controlPoint.isCompleted) {
        await ControlPointService()
            .markControlPointAsIncomplete(controlPoint.id!);
      } else {
        await ControlPointService()
            .markControlPointAsCompleted(controlPoint.id!);
      }
      // Обновляем UI через setState в родительском виджете
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controlPoint.isCompleted
                ? 'Контрольная точка отмечена как невыполненная'
                : 'Контрольная точка отмечена как выполненная'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  void _showCheckProgressMenu(BuildContext context, Task task) {
    // Получаем имя исполнителя для отображения в меню
    String executorName = _getExecutorName(task);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Проверить ход работы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: Text('Позвонить $executorName'),
                subtitle: Text(_getExecutorPhone(task) ?? 'Номер не указан'),
                onTap: () {
                  Navigator.pop(context);
                  _callExecutor(context, task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.blue),
                title: const Text('Написать в чат'),
                onTap: () {
                  Navigator.pop(context);
                  _openTaskChat(context, task);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _callExecutor(BuildContext context, Task task) async {
    // Получаем номер телефона исполнителя
    String? phoneNumber = _getExecutorPhone(task);

    // Если номер не найден, используем заглушку
    if (phoneNumber == null || phoneNumber.isEmpty) {
      phoneNumber = '+7XXXXXXXXXX';
    }

    final url = 'tel:$phoneNumber';

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Не удалось открыть приложение телефона')),
        );
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при открытии телефона: $e')),
      );
    }
  }

  void _openTaskChat(BuildContext context, Task task) {
    // Здесь должна быть логика для открытия чата задачи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Открытие чата задачи')),
    );
  }

  // Вспомогательный метод для получения имени исполнителя
  String _getExecutorName(Task task) {
    // Сначала проверяем teamMembers (исполнители)
    if (task.team.teamMembers.isNotEmpty) {
      return task.team.teamMembers.first.name;
    }

    // Если нет исполнителей, возвращаем имя создателя
    return task.team.creatorId.name;
  }

  // Вспомогательный метод для получения телефона исполнителя
  String? _getExecutorPhone(Task task) {
    // Сначала проверяем teamMembers (исполнители)
    if (task.team.teamMembers.isNotEmpty) {
      final executor = task.team.teamMembers.first;
      if (executor.phone != null && executor.phone!.isNotEmpty) {
        return executor.phone;
      }
    }

    // Если нет исполнителей или у них нет телефона, проверяем создателя
    if (task.team.creatorId.phone != null &&
        task.team.creatorId.phone!.isNotEmpty) {
      return task.team.creatorId.phone;
    }

    return null;
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
