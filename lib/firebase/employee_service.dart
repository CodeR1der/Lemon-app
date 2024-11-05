import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/models/employee.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();

  // Добавление сотрудника в Firestore
  Future<void> addEmployee(Employee employee) async {
    // Генерация нового userId, если он не указан
    if (employee.userId.isEmpty) {
      employee.userId = _uuid.v4();
    }

    try {
      await _firestore.collection('employees').doc(employee.userId).set(employee.toJson());
    } catch (e) {
      print('Ошибка при добавлении сотрудника: $e');
    }
  }

  // Получение списка всех сотрудников
  Future<List<Employee>> getAllEmployees() async {
    try {
      // Получаем коллекцию сотрудников из Firestore
      QuerySnapshot querySnapshot = await _firestore.collection('employees').get();

      // Преобразуем документы Firestore в объекты Employee
      List<Employee> employeeList = querySnapshot.docs.map((doc) {
        return Employee.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      return employeeList;
    } catch (e) {
      print('Ошибка при получении списка сотрудников: $e');
      return [];
    }
  }

  // Получение данных сотрудника по userId
  Future<Employee?> getEmployee(String userId) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('employees').doc(userId).get();
      if (docSnapshot.exists) {
        return Employee.fromJson(docSnapshot.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Ошибка при получении данных сотрудника: $e');
    }
    return null;
  }

  // Обновление данных сотрудника
  Future<void> updateEmployee(Employee employee) async {
    try {
      await _firestore.collection('employees').doc(employee.userId).update(employee.toJson());
    } catch (e) {
      print('Ошибка при обновлении данных сотрудника: $e');
    }
  }

  // Удаление сотрудника
  Future<void> deleteEmployee(String userId) async {
    try {
      await _firestore.collection('employees').doc(userId).delete();
    } catch (e) {
      print('Ошибка при удалении сотрудника: $e');
    }
  }
}
