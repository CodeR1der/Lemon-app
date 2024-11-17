class Employee {
  late String userId;
  late String name;
  late String position;
  late String phone;
  late String telegramId;
  late String vkId;
  String? avatarFileName; // Поле для хранения имени файла аватара

  // Конструктор
  Employee({
    required this.userId,
    required this.name,
    required this.position,
    required this.phone,
    required this.telegramId,
    required this.vkId,
    this.avatarFileName, // Поле для аватара
  });

  // Преобразование объекта в JSON для хранения в Supabase
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'position': position,
      'phone': phone,
      'telegramId': telegramId,
      'vkId': vkId,
      'avatarFileName': avatarFileName,
    };
  }

  // Создание объекта Employee из JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      userId: json['userId'],
      name: json['name'],
      position: json['position'],
      phone: json['phone'],
      telegramId: json['telegramId'],
      vkId: json['vkId'],
      avatarFileName: json['avatarFileName'], // Добавляем из JSON
    );
  }

  // Проверка валидности номера телефона
  bool isPhoneValid() {
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,13}$'); // Пример регулярного выражения
    return phoneRegExp.hasMatch(phone);
  }
}
