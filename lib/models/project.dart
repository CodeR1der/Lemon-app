class Project{
  late String project_id;
  late String name;
  late String? avatar_url;

  // Конструктор
  Project({
    required this.project_id,
    required this.name,
    this.avatar_url,
  });

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'project_id': project_id,
      'name': name,
      'avatar_url': avatar_url,
    };
  }

  // Создание объекта Employee из JSON
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
        project_id: json['project_id'],
        name: json['name'],
        avatar_url: json['avatar_url'],
    );
  }

}