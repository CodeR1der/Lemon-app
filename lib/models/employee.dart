import 'package:uuid/uuid.dart';

class Employee {
  late String userId;
  late String employeeId;
  late String name;
  late String position;
  late String phone;
  late String telegramId;
  late String vkId;

  // Конструктор
  Employee({
    required this.employeeId,
    required this.name,
    required this.position,
    required this.phone,
    required this.telegramId,
    required this.vkId,
  }) {
    // Генерация GUID для userId
    userId = Uuid().v4(); // Использование библиотеки uuid
  }

  // Преобразование объекта в JSON для хранения в Firebase
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'employeeId': employeeId,
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
      employeeId: json['employeeId'],
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
