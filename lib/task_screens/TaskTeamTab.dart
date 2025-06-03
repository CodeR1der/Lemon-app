import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/task.dart';
import '../services/task_operations.dart';

class TaskTeamTab extends StatelessWidget {
  final Task task;
  final TaskService _database = TaskService();

  TaskTeamTab({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final team = task.team;
    final hasTeamMembers = team.teamMembers.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Постановщик (creator)
            if (hasTeamMembers)
              _buildTeamMemberSection(
                context: context,
                title: 'Постановщик',
                employees: [team.creatorId],
              ),

            // Коммуникатор
            if (hasTeamMembers)
              _buildTeamMemberSection(
                context: context,
                title: 'Коммуникатор',
                employees: [team.communicatorId],
              ),

            // Исполнители (все кроме creator и communicator)
            if (hasTeamMembers)
              _buildTeamMemberSection(
                context: context,
                title: 'Исполнители',
                employees: team.teamMembers
                    .where((member) =>
                        member.userId != team.creatorId.userId &&
                        member.userId != team.communicatorId.userId)
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberSection({
    required BuildContext context,
    required String title,
    required List<Employee> employees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (var employee in employees)
          ListTile(
            contentPadding: EdgeInsets.zero,
            // Убраны внутренние отступы ListTile
            leading: CircleAvatar(
              backgroundImage:
                  NetworkImage(_database.getAvatarUrl(employee.avatarUrl)),
              radius: 20,
            ),
            title: Text(
              employee.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              employee.position,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
      ],
    );
  }
}
