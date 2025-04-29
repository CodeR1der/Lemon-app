import 'package:task_tracker/models/employee.dart';

class Project{
  late String projectId;
  late String name;
  late String? avatarUrl;
  final List<Employee> observers;

  // Конструктор
  Project({
    required this.projectId,
    required this.name,
    this.avatarUrl,
    required this.observers
  });

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