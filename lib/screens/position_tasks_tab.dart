import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/screens/tasks_list_screen.dart';

import '../models/task_category.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../services/task_categories.dart';
import '../services/task_provider.dart';
import 'employee_queue_screen.dart';

class PositionTasksTab extends StatefulWidget {
  final String? position;
  final String? employeeId;
  final String? projectId;

  const PositionTasksTab({
    Key? key,
    this.position,
    this.employeeId,
    this.projectId,
  }) : super(key: key);

  @override
  State<PositionTasksTab> createState() => _PositionTasksTabState();
}

class _PositionTasksTabState extends State<PositionTasksTab> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (widget.projectId != null) {
        taskProvider.loadTasksAndCategories(
          taskCategories: TaskCategories(),
          projectId: widget.projectId,
        );
      } else if (widget.position != null && widget.employeeId != null) {
        taskProvider.loadTasksAndCategories(
          taskCategories: TaskCategories(),
          position: widget.position!,
          employeeId: widget.employeeId!,
        );
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final categories = taskProvider.getCategories(
          widget.position ?? '',
          widget.employeeId ?? '',
          projectId: widget.projectId,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
            padding: const EdgeInsets.all(1.0),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(context, category);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, TaskCategory category) {
    final icon = StatusHelper.getStatusIcon(category.status);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        category.title,
        style: const TextStyle(fontSize: 16.0),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          category.count.toString(),
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _handleCategoryTap(context, category),
    );
  }

  void _handleCategoryTap(BuildContext context, TaskCategory category) {
    try {
      if (widget.projectId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListByStatusScreen(
              projectId: widget.projectId!,
              status: category.status,
            ),
          ),
        );
      } else if (widget.position != null && widget.employeeId != null) {
        if ((widget.position == RoleHelper.convertToString(TaskRole.executor) ||
            widget.position == RoleHelper.convertToString(TaskRole.creator)) &&
            category.status == TaskStatus.queue) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QueueScreen(
                position: widget.position!,
                userId: widget.employeeId!,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskListByStatusScreen(
                position: widget.position!,
                userId: widget.employeeId!,
                status: category.status,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: ${e.toString()}')),
      );
    }
  }
}