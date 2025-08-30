class Employee {
  late String userId;
  late String firstName;
  late String lastName;
  late String? middleName;
  late String position;
  late String? phone;
  late String? telegramId;
  late String? vkId;
  late String role;
  late String companyId;
  String? avatarUrl;

  // Конструктор
  Employee({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.position,
    this.phone,
    this.telegramId,
    this.vkId,
    this.avatarUrl,
    required this.role,
    required this.companyId,
  });

  // Геттер для полного имени
  String get fullName {
    if (middleName != null) {
      return '$lastName $firstName $middleName';
    }
    return '$lastName $firstName';
  }

  // Геттер для краткого имени (Фамилия И.О.)
  String get shortName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$lastName ${firstName[0]}.${middleName![0]}.';
    }
    return '$lastName ${firstName[0]}.';
  }

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
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
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
      position: json['position'],
      phone: json['phone'],
      telegramId: json['telegram_id'],
      vkId: json['vk_id'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      companyId: json['company_id'],
    );
  }

  Employee copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? middleName,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      telegramId: telegramId ?? this.telegramId,
      vkId: vkId ?? this.vkId,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'Employee(userId: $userId, fullName: $fullName, position: $position, role: $role)';
  }
}