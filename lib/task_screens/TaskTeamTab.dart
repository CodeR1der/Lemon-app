import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/employee.dart';
import '../services/task_operations.dart';  // Import the Employee model (assuming you have it)

class TaskTeamTab extends StatelessWidget {
  final Task task;
  TaskTeamTab({super.key, required this.task});
  final TaskService _database = TaskService();

  @override
  Widget build(BuildContext context) {
    // Example list of employees, you should replace it with actual employee data from your task object
    List<Employee> team = [];
    team.addAll(task.team);
    team.addAll(task.project!.observers);

    // Check if team has enough members before displaying them
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check if there's at least one employee for "Постановщик"
          if (team.isNotEmpty)
            _buildTeamMemberSection(title: 'Постановщик', employees: [team[0]]),
          const SizedBox(height: 16.0),

          // Check if there's at least two employees for "Коммуникатор"
          if (team.length > 1)
            _buildTeamMemberSection(title: 'Коммуникатор', employees: [team[1]]),
          const SizedBox(height: 16.0),

          // Check if there's at least three employees for "Исполнитель"
          if (team.length > 2)
            _buildTeamMemberSection(title: 'Исполнитель', employees: [team[2]]),
          const SizedBox(height: 16.0),

          // Check if there are more than three employees for "Наблюдатели"
          if (team.length > 3)
            _buildTeamMemberSection(title: 'Наблюдатели', employees: team.sublist(3)),
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8.0),
        for (var employee in employees)
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(_database.getAvatarUrl(employee.avatarUrl)),  // Assuming avatarUrl is available in Employee model
            ),
            title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(employee.position),  // Assuming position is available in Employee model
          ),
      ],
    );
  }
}
