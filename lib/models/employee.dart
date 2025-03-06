class Employee {
  late String user_id;
  late String name;
  late String position;
  late String? phone;
  late String? telegram_id;
  late String? vk_id;
  late String role;
  String? avatar_url; // Поле для хранения имени файла аватара

  // Конструктор
  Employee({
    required this.user_id,
    required this.name,
    required this.position,
    required this.phone,
    required this.telegram_id,
    required this.vk_id,
    this.avatar_url,
    required this.role,
  });

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'name': name,
      'position': position,
      'phone': phone,
      'telegram_id': telegram_id,
      'vk_id': vk_id,
      'avatar_url': avatar_url,
      'role' : role
    };
  }

  // Создание объекта Employee из JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      user_id: json['user_id'],
      name: json['name'],
      position: json['position'],
      phone: json['phone'],
      telegram_id: json['telegram_id'],
      vk_id: json['vk_id'],
      avatar_url: json['avatar_url'],
      role: json['role']
    );
  }
}
