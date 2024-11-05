
class Employee {
  late String userId;
  late String name;
  late String position;
  late String phone;
  late String telegramId;
  late String vkId;

  // Конструктор
  Employee({
    required this.userId,
    required this.name,
    required this.position,
    required this.phone,
    required this.telegramId,
    required this.vkId,
  });

  // Преобразование объекта в JSON для хранения в Firebase
  toJson() {
    return {
      'userId': userId,
      'name': name,
      'position': position,
      'phone': phone,
      'telegramId': telegramId,
      'vkId': vkId,
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
    );
  }

  // Проверка валидности номера телефона с использованием регулярного выражения
  bool isPhoneValid() {
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,13}$'); // Пример регулярного выражения
    return phoneRegExp.hasMatch(phone);
  }
}
