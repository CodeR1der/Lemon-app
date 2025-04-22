import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/priority.dart';
import '../models/task.dart';
import '../models/task_status.dart';

class CategoryTasksListScreen extends StatelessWidget {
  final String categoryTitle;
  final List<Task> tasks;

  const CategoryTasksListScreen({
    Key? key,
    required this.categoryTitle,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentTask = tasks.isNotEmpty ? tasks.first : null;
    final totalTasks = tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              categoryTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (currentTask != null) _buildTaskDetails(currentTask),
            const SizedBox(height: 16),
            _buildTaskList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(int completed, int total) {
    final now = DateTime.now();
    final formattedTime = DateFormat('H:m').format(now);
    final progressRatio = '$completed:$total';

    return Row(
      children: [
        Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          progressRatio,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetails(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusSection(task),
        const SizedBox(height: 16),
        _buildProjectSection(task),
        const SizedBox(height: 16),
        _buildPrioritySection(task),
        const SizedBox(height: 16),
        _buildDatesSection(task),
      ],
    );
  }

  Widget _buildStatusSection(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статус',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text(
            task.status.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(task.taskName),
          value: task.status == TaskStatus.completedUnderReview,
          onChanged: (bool? value) {
            // Здесь будет логика изменения статуса
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildProjectSection(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Проект',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          task.project?.name ?? 'Не указан',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPrioritySection(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Приоритет',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          task.priorityToString(),
          style: TextStyle(
            fontSize: 16,
            color: _getPriorityColor(task.priority),
          ),
        ),
      ],
    );
  }

  Widget _buildDatesSection(Task task) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сроки',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${dateFormat.format(task.startDate)} - ${dateFormat.format(task.endDate)}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Все задачи в категории',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              title: Text(task.taskName),
              subtitle: Text(task.project?.name ?? ''),
              trailing: Text(task.priorityToString()),
              onTap: () {
                // Переход к детальной странице задачи
              },
            );
          },
        ),
      ],
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }
}