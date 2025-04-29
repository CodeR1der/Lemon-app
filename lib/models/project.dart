import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/models/project_description.dart';

class Project {
  late String projectId;
  late String name;
  late String? avatarUrl;
  late ProjectDescription? projectDescription;
  final List<Employee> observers;

  // Конструктор
  Project(
      {required this.projectId,
      required this.name,
      this.avatarUrl,
      this.projectDescription,
      required this.observers});

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'name': name,
      'avatar_url': avatarUrl,
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
      observers: json['project_observers'] != null
          ? List<Employee>.from(
              json['project_observers'].map((observer) {
                return Employee.fromJson(observer['employee']);
              }),
            )
          : <Employee>[],
    );
  }
}
