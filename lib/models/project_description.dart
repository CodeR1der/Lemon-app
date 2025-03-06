class Project_Description{
  late String project_id;
  late String description;
  late String goals;
  final String projectLink;
  final Map<String, dynamic> socialNetworks;

  // Конструктор
  Project_Description({
    required this.project_id,
    required this.description,
    required this.goals,
    required this.projectLink,
    required this.socialNetworks,
  });

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'project_id': project_id,
      'description': description,
      'goals': goals,
      'project_link': projectLink,
      'social_networks': socialNetworks,
    };
  }

  // Создание объекта Employee из JSON
  factory Project_Description.fromJson(Map<String, dynamic> json) {
    return Project_Description(
      project_id: json['project_id'],
      description: json['description'],
      goals: json['goals'],
      projectLink: json['project_link'],
      socialNetworks: json['social_networks'] ?? {},
    );
  }

}