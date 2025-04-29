class ProjectDescription {
  late String project_description_id;
  late String description;
  late String goals;
  final String projectLink;
  final Map<String, dynamic> socialNetworks;

  // Конструктор
  ProjectDescription({
    required this.project_description_id,
    required this.description,
    required this.goals,
    required this.projectLink,
    required this.socialNetworks,
  });

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'project_description_id': project_description_id,
      'description': description,
      'goals': goals,
      'project_link': projectLink,
      'social_networks': socialNetworks,
    };
  }

  // Создание объекта Employee из JSON
  factory ProjectDescription.fromJson(Map<String, dynamic> json) {
    return ProjectDescription(
      project_description_id: json['project_description_id'],
      description: json['description'],
      goals: json['goals'],
      projectLink: json['project_link'],
      socialNetworks: json['social_networks'] ?? {},
    );
  }
}
