import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/models/project_description.dart';

class Project {
  late String projectId;
  late String name;
  late String? avatarUrl;
  late ProjectDescription? projectDescription;
  final List<Employee> team;
  final String companyId;

  // Конструктор
  Project(
      {required this.projectId,
      required this.name,
      this.avatarUrl,
      this.projectDescription,
      required this.team,
      required this.companyId});

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'name': name,
      'avatar_url': avatarUrl,
      'project_description_id': projectDescription!.projectDescriptionId,
      'company_id': companyId
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['project_id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      projectDescription: json['project_description_id'] != null
          ? ProjectDescription.fromJson(json['project_description_id'])
          : null,
      team: json['team'] != null
          ? List<Employee>.from(
              json['team'].map((observer) {
                return Employee.fromJson(observer['employee']);
              }),
            )
          : <Employee>[],
      companyId: json['company_id']
    );
  }
}
