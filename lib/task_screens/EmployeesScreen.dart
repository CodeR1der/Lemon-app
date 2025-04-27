import 'package:flutter/material.dart';
import 'package:task_tracker/services/task_operations.dart';
import 'package:task_tracker/task_screens/DeadlineScreen.dart';
import '../models/employee.dart';
import '../models/task.dart';

class EmployeeSelectionScreen extends StatefulWidget {
  final Task taskData;

  const EmployeeSelectionScreen(this.taskData, {super.key});

  @override
  _EmployeeSelectionScreenState createState() =>
      _EmployeeSelectionScreenState();
}

class _EmployeeSelectionScreenState extends State<EmployeeSelectionScreen> {
  late Future<List<Employee>> employeesFuture;
  Employee? selectedPerformer;
  Employee? selectedCommunicator;
  Employee? selectedObserver;
  final TaskService _database = TaskService();

  @override
  void initState() {
    super.initState();
    employeesFuture = loadEmployees();
  }

  Future<List<Employee>> loadEmployees() async {
    return _database.getAllEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор сотрудников'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Employee>>(
          future: employeesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка загрузки сотрудников'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Нет доступных сотрудников'));
            }

            final employees = snapshot.data!;

            return Column(
              children: <Widget>[
                _buildEmployeeSelectionTile(
                  title: 'Исполнитель',
                  selectedEmployee: selectedPerformer,
                  onSelected: (Employee? employee) {
                    if (_isEmployeeAlreadySelected(employee)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Этот сотрудник уже выбран')),
                      );
                    } else {
                      setState(() {
                        selectedPerformer = employee;
                      });
                    }
                  },
                  employees: employees,
                ),
                const SizedBox(height: 16),
                _buildEmployeeSelectionTile(
                  title: 'Коммуникатор',
                  selectedEmployee: selectedCommunicator,
                  onSelected: (Employee? employee) {
                    if (_isEmployeeAlreadySelected(employee)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Этот сотрудник уже выбран')),
                      );
                    } else {
                      setState(() {
                        selectedPerformer = employee;
                      });
                    }
                  },
                  employees: employees,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Наблюдатели',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      // Чтобы список правильно встраивался в Column
                      physics: const NeverScrollableScrollPhysics(),
                      // Отключаем отдельный скроллинг
                      itemCount: widget.taskData.project?.observers.length,
                      itemBuilder: (context, index) {
                        final observer =
                            widget.taskData.project?.observers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(_database
                                .getAvatarUrl(observer!.avatarUrl)),
                          ),
                          title: Text(
                            observer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(observer.position),
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedPerformer != null &&
                          selectedCommunicator != null) {
                        widget.taskData.team = [
                          selectedPerformer,
                          selectedCommunicator,
                          selectedObserver,
                        ].whereType<Employee>().toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DeadlineScreen(widget.taskData),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Дальше'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isEmployeeAlreadySelected(Employee? employee) {
    if (employee == null) return false;
    return employee == selectedPerformer ||
        employee == selectedCommunicator ||
        employee == selectedObserver;
  }

  Widget _buildEmployeeSelectionTile({
    required String title,
    required Employee? selectedEmployee,
    required ValueChanged<Employee?> onSelected, // Изменено на Employee?
    required List<Employee> employees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButton<Employee>(
            value: selectedEmployee,
            hint: const Text('Выберите сотрудника'),
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            underline: Container(),
            onChanged: onSelected,
            items: employees.map((employee) {
              return DropdownMenuItem<Employee>(
                value: employee,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                          _database.getAvatarUrl(employee.avatarUrl)),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(employee.name),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
