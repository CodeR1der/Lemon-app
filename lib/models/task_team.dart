import 'package:task_tracker/models/employee.dart';

class TaskTeam {
  late String teamId;
  late String taskId;
  late String communicatorId;
  late String creatorId;
  final List<Employee> teamMembers;

  TaskTeam({
    required this.teamId,
    required this.taskId,
    required this.communicatorId,
    required this.creatorId,
    required this.teamMembers
  });

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'task_id': taskId,
      'communicator_id': communicatorId,
      'creator_id': creatorId
    };
  }

  factory TaskTeam.fromJson(Map<String, dynamic> json) {
    return TaskTeam(
      teamId: json['team_id'],
      taskId: json['task_id'],
      communicatorId: json['communicator_id'],
      creatorId: json['creator_id'],
      teamMembers: json['team_members'] != null
        ? List<Employee>.from(
        json['team_members'].map((member) {
      return Employee.fromJson(member['employee']);
    }),
      )
          : <Employee>[],
    );
  }
}