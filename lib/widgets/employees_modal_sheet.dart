import 'package:flutter/material.dart';
import 'package:task_tracker/models/employee.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/widgets/common/app_common.dart';

class EmployeesModalSheet extends StatefulWidget {
  final List<Employee> allEmployees;
  final Set<String> selectedEmployeeIds;
  final Function(Set<String>) onEmployeesSelected;

  const EmployeesModalSheet({
    super.key,
    required this.allEmployees,
    required this.selectedEmployeeIds,
    required this.onEmployeesSelected,
  });

  @override
  State<EmployeesModalSheet> createState() => _EmployeesModalSheetState();
}

class _EmployeesModalSheetState extends State<EmployeesModalSheet> {
  late Set<String> _selectedEmployeeIds;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeIds = Set.from(widget.selectedEmployeeIds);
  }

  void _toggleEmployeeSelection(String employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
  }

  void _selectAllEmployees() {
    setState(() {
      _selectedEmployeeIds = widget.allEmployees.map((e) => e.userId).toSet();
    });
  }

  void _deselectAllEmployees() {
    setState(() {
      _selectedEmployeeIds.clear();
    });
  }

  void _confirmSelection() {
    widget.onEmployeesSelected(_selectedEmployeeIds);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isAll = _selectedEmployeeIds.length == widget.allEmployees.length;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Сотрудники',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                ),
              ],
            ),
          ),

          // Select all option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: isAll,
                  onChanged: widget.allEmployees.isNotEmpty ? (bool? value) {
                    if (value == true) {
                      _selectAllEmployees();
                    } else {
                      _deselectAllEmployees();
                    }

                  } : null,
                  activeColor: Colors.blueAccent, // Основной цвет при выборе
                  checkColor: Colors.white, // Цвет галочки
                  fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                    return states.contains(MaterialState.selected)
                        ? Colors.blueAccent
                        : Colors.transparent;
                  }),
                  side: MaterialStateBorderSide.resolveWith((states) {
                    // Если чекбокс выбран - цвет рамки как заливка, иначе surfaceVariant
                    final color = states.contains(MaterialState.selected)
                        ? Colors.blueAccent
                        : Theme.of(context).colorScheme.surfaceVariant;
                    return BorderSide(
                      width: 2.0,
                      color: color,
                    );
                  }),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'Выбрать всех',
                  style: AppTextStyles.titleMedium,
                ),
              ],
            ),
          ),

          AppCommonWidgets.divider(),

          // Employees list
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.allEmployees.length,
              itemBuilder: (context, index) {
                final employee = widget.allEmployees[index];
                final isSelected =
                    _selectedEmployeeIds.contains(employee.userId);

                return ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleEmployeeSelection(employee.userId);
                    },
                    activeColor: Colors.blueAccent, // Основной цвет при выборе
                    checkColor: Colors.white, // Цвет галочки
                    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                      return states.contains(MaterialState.selected)
                          ? Colors.blueAccent
                          : Colors.transparent;
                    }),
                    side: MaterialStateBorderSide.resolveWith((states) {
                      // Если чекбокс выбран - цвет рамки как заливка, иначе surfaceVariant
                      final color = states.contains(MaterialState.selected)
                          ? Colors.blueAccent
                          : Theme.of(context).colorScheme.surfaceVariant;
                      return BorderSide(
                        width: 2.0,
                        color: color,
                      );
                    }),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: employee.avatarUrl != null &&
                                employee.avatarUrl!.isNotEmpty
                            ? NetworkImage(EmployeeService()
                                .getAvatarUrl(employee.avatarUrl!))
                            : null,
                        backgroundColor: employee.avatarUrl == null ||
                                employee.avatarUrl!.isEmpty
                            ? Colors.blue[100]
                            : null,
                        child: employee.avatarUrl == null ||
                                employee.avatarUrl!.isEmpty
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              employee.position,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _toggleEmployeeSelection(employee.userId);
                  },
                );
              },
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Подтвердить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
