class ProjectDescription {
  late String projectDescriptionId;
  late String description;
  late String goals;
  final String projectLink;
  final Map<String, dynamic> socialNetworks;

  // Конструктор
  ProjectDescription({
    required this.projectDescriptionId,
    required this.description,
    required this.goals,
    required this.projectLink,
    required this.socialNetworks,
  });

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'project_description_id': projectDescriptionId,
      'description': description,
      'goals': goals,
      'project_link': projectLink,
      'social_networks': socialNetworks,
    };
  }

  // Создание объекта Employee из JSON
  factory ProjectDescription.fromJson(Map<String, dynamic> json) {
    return ProjectDescription(
      projectDescriptionId: json['project_description_id'],
      description: json['description'],
      goals: json['goals'],
      projectLink: json['project_link'],
      socialNetworks: json['social_networks'] ?? {},
    );
  }
}
