import 'package:flutter/material.dart';
import 'package:task_tracker/models/control_point.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/control_point_operations.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';

import 'add_control_point_screen.dart';

class ControlPointScreen extends StatefulWidget {
  final Task task;

  const ControlPointScreen({super.key, required this.task});

  @override
  State<ControlPointScreen> createState() => _ControlPointScreenState();
}

class _ControlPointScreenState extends State<ControlPointScreen> {
  List<ControlPoint> _controlPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadControlPoints();
  }

  Future<void> _loadControlPoints() async {
    try {
      final controlPoints =
          await ControlPointService().getControlPointsForTask(widget.task.id);
      setState(() {
        _controlPoints = controlPoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {

      }
    }
  }

  Future<void> _addControlPoint() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddControlPointScreen(task: widget.task),
      ),
    );

    if (result == true) {
      _loadControlPoints();
    }
  }

  Future<void> _markAsCompleted(ControlPoint controlPoint) async {
    try {
      await ControlPointService().markControlPointAsCompleted(
        controlPoint.id!,
      );
      _loadControlPoints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Контрольная точка отмечена как выполненная')),
        );
      }
    } catch (e) {
      if (mounted) {

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Контрольные точки - ${widget.task.taskName}'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _controlPoints.isEmpty
                ? _buildEmptyState()
                : _buildControlPointsList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addControlPoint,
        backgroundColor: const Color(0xFFFF9700),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет контрольных точек',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте контрольные точки для отслеживания прогресса',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButtons.primaryButton(
            onPressed: _addControlPoint,
            text: 'Добавить контрольную точку',
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildControlPointsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _controlPoints.length,
      itemBuilder: (context, index) {
        final controlPoint = _controlPoints[index];
        return _buildControlPointCard(controlPoint);
      },
    );
  }

  Widget _buildControlPointCard(ControlPoint controlPoint) {
    final isOverdue =
        !controlPoint.isCompleted && controlPoint.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controlPoint.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: controlPoint.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                ),
                if (!controlPoint.isCompleted)
                  IconButton(
                    onPressed: () => _markAsCompleted(controlPoint),
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controlPoint.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: controlPoint.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isOverdue ? Colors.red : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Срок: ${controlPoint.date.day}.${controlPoint.date.month}.${controlPoint.date.year}',
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.grey[600],
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ПРОСРОЧЕНО',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (controlPoint.isCompleted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Выполнено ${controlPoint.completedAt != null ? '${controlPoint.completedAt!.day}.${controlPoint.completedAt!.month}.${controlPoint.completedAt!.year}' : ''}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
