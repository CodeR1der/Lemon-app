import 'package:task_tracker/models/employee.dart';

class TaskTeam {
  late String teamId;
  late String taskId;
  late Employee communicatorId;
  late Employee creatorId;
  late Employee? observerId;
  late List<Employee> teamMembers;

  TaskTeam(
      {required this.teamId,
      required this.taskId,
      required this.communicatorId,
      required this.creatorId,
      this.observerId,
      required this.teamMembers});

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'task_id': taskId,
      'communicator_id': communicatorId.userId,
      'observer_id': observerId?.userId,
      'creator_id': creatorId.userId
    };
  }

  factory TaskTeam.fromJson(Map<String, dynamic> json) {
    return TaskTeam(
      teamId: json['team_id'] as String,
      taskId: json['task_id'] as String,
      communicatorId:
          Employee.fromJson(json['communicator_id'] as Map<String, dynamic>),
      creatorId: Employee.fromJson(json['creator_id'] as Map<String, dynamic>),
      observerId: json['observer_id'] != null
          ? Employee.fromJson(json['observer_id'] as Map<String, dynamic>)
          : null,
      teamMembers: json['team_members'] != null
          ? List<Employee>.from(
              (json['team_members'] as List).map(
                (member) => Employee.fromJson(
                    member['employee_id'] as Map<String, dynamic>),
              ),
            )
          : <Employee>[],
    );
  }

  TaskTeam.empty() {
    teamId = '';
    taskId = '';
    communicatorId = Employee(
      userId: '',
      position: '',
      phone: '',
      telegramId: '',
      vkId: '',
      role: '',
      companyId: '', firstName: '', lastName: '',
    );
    creatorId = Employee(
      userId: '',
      position: '',
      phone: '',
      telegramId: '',
      vkId: '',
      role: '',
      companyId: '', firstName: '', lastName: '',
    );
    observerId = null;
    teamMembers = [];
  }
}
