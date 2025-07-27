class Employee {
  late String userId;
  late String name;
  late String position;
  late String? phone;
  late String? telegramId;
  late String? vkId;
  late String role;
  late String companyId;
  String? avatarUrl; // Поле для хранения имени файла аватара

  // Конструктор
  Employee(
      {required this.userId,
      required this.name,
      required this.position,
      required this.phone,
      required this.telegramId,
      required this.vkId,
      this.avatarUrl,
      required this.role,
      required this.companyId});

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'position': position,
      'phone': phone,
      'telegram_id': telegramId,
      'vk_id': vkId,
      'avatar_url': avatarUrl,
      'role': role,
      'company_id': companyId
    };
  }

  // Создание объекта Employee из JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
        userId: json['user_id'],
        name: json['name'],
        position: json['position'],
        phone: json['phone'],
        telegramId: json['telegram_id'],
        vkId: json['vk_id'],
        avatarUrl: json['avatar_url'],
        role: json['role'],
        companyId: json['company_id']);
  }

  Employee copyWith({
    String? userId,
    String? name,
    String? position,
    String? phone,
    String? telegramId,
    String? vkId,
    String? role,
    String? companyId,
    String? avatarUrl,
  }) {
    return Employee(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      telegramId: telegramId ?? this.telegramId,
      vkId: vkId ?? this.vkId,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
