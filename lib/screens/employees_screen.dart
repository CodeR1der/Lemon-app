import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../firebase/employee_service.dart';
import '../widgets/navigation_panel.dart';
import 'employee_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  EmployeeService _employeeService = EmployeeService();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_filterEmployees);
  }

  Future<void> _loadEmployees() async {
    List<Employee> employees = await _employeeService.getAllEmployees();
    setState(() {
      _employees = employees;
      _filteredEmployees = employees;
    });
  }

  void _filterEmployees() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees
          .where((employee) => employee.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero, // Убираем стандартные отступы
              itemCount: _filteredEmployees.length,
              itemBuilder: (context, index) {
                Employee employee = _filteredEmployees[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    employee.name,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  subtitle: Text(
                    employee.position,
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 13,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeDetailScreen(employee: employee),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 3), // Навигационная панель
    );
  }
}
