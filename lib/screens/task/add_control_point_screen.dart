import 'package:flutter/material.dart';
import 'package:task_tracker/models/control_point.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/control_point_operations.dart';
import 'package:task_tracker/widgets/common/app_buttons.dart';
import 'package:task_tracker/widgets/common/app_common_widgets.dart';

class AddControlPointScreen extends StatefulWidget {
  final Task task;

  const AddControlPointScreen({super.key, required this.task});

  @override
  State<AddControlPointScreen> createState() => _AddControlPointScreenState();
}

class _AddControlPointScreenState extends State<AddControlPointScreen> {
  final _descriptionController = TextEditingController();

  DateTime? selectedDate;
  DateTime _focusedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool _canSubmit() {
    return selectedDate != null;
  }

  Future<void> _submitControlPoint() async {
    if (!_canSubmit()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controlPoint = ControlPoint(
        taskId: widget.task.id,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'Контрольная точка на ${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}',
        date: selectedDate!,
      );

      await ControlPointService().addControlPoint(controlPoint);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Контрольная точка успешно добавлена')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Выставить контрольную точку - ${widget.task.taskName}'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название задачи
              Text(
                'Название задачи №${widget.task.id}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.taskName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Календарь
              AppCommonWidgets.calendar(
                focusedDate: _focusedDate,
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                onMonthChanged: (date) {
                  setState(() {
                    _focusedDate = date;
                  });
                },
                onYearChanged: (date) {
                  setState(() {
                    _focusedDate = date;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding),
        child: AppButtons.primaryButton(
          onPressed: _canSubmit() && !_isLoading ? _submitControlPoint : () {},
          text: _isLoading ? 'Добавление...' : 'Выставить контрольную точку',
          isLoading: _isLoading,
        ),
      ),
    );
  }
}
