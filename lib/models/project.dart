import 'package:task_tracker/models/employee.dart';

class Project{
  late String project_id;
  late String name;
  late String? avatar_url;
  final List<Employee> observers;

  // Конструктор
  Project({
    required this.project_id,
    required this.name,
    this.avatar_url,
    required this.observers
  });

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'project_id': project_id,
      'name': name,
      'avatar_url': avatar_url,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      project_id: json['project_id'],
      name: json['name'],
      avatar_url: json['avatar_url'],
      observers: json['project_observers'] != null
          ? List<Employee>.from(
        json['project_observers'].map((observer) {
          return Employee.fromJson(observer['employee']);
        }),
      )
          : <Employee>[], // Если project_observers равен null, возвращаем пустой список
    );
  }

}