import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../models/task.dart';
import '../services/task_operations.dart'; // Import the Employee model (assuming you have it)

class TaskTeamTab extends StatelessWidget {
  final Task task;

  TaskTeamTab({super.key, required this.task});

  final TaskService _database = TaskService();

  @override
  Widget build(BuildContext context) {
    final team = task.team;
    final hasTeamMembers = team.teamMembers.isNotEmpty;
    final hasObservers = task.project?.observers.isNotEmpty ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Постановщик (creator)
          if (hasTeamMembers)
            _buildTeamMemberSection(
              title: 'Постановщик',
              employees: [team.creatorId],
            ),
          const SizedBox(height: 16.0),

          // Коммуникатор
          if (hasTeamMembers)
            _buildTeamMemberSection(
              title: 'Коммуникатор',
              employees: [team.communicatorId],
            ),
          const SizedBox(height: 16.0),

          // Исполнители (все кроме creator и communicator)
          if (hasTeamMembers)
            _buildTeamMemberSection(
              title: 'Исполнители',
              employees: team.teamMembers
                  .where((member) =>
                      member.userId != team.creatorId &&
                      member.userId != team.communicatorId)
                  .toList(),
            ),
          const SizedBox(height: 16.0),

          // Наблюдатели из проекта
          if (hasObservers)
            _buildTeamMemberSection(
              title: 'Наблюдатели',
              employees: task.project!.observers,
            ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberSection({
    required String title,
    required List<Employee> employees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8.0),
        for (var employee in employees)
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  NetworkImage(_database.getAvatarUrl(employee.avatarUrl)),
            ),
            title: Text(employee.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(employee.position),
          ),
      ],
    );
  }
}
