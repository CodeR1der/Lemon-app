import 'package:flutter/material.dart';
import 'package:task_tracker/widgets/common/app_common_widgets.dart';
import 'package:task_tracker/widgets/common/app_spacing.dart';
import 'package:task_tracker/widgets/common/app_text_styles.dart';

class SelectPeriodScreen extends StatefulWidget {
  final DateTime selectedStartDate;
  final DateTime selectedEndDate;

  const SelectPeriodScreen({
    required this.selectedStartDate,
    required this.selectedEndDate,
    super.key,
  });

  @override
  _SelectPeriodScreenState createState() => _SelectPeriodScreenState();
}

class _SelectPeriodScreenState extends State<SelectPeriodScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.selectedStartDate;
    _rangeStart = widget.selectedStartDate;
    _rangeEnd = widget.selectedEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Выбор периода'),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Календарь с поддержкой диапазона
              AppCommonWidgets.calendar(
                focusedDate: _focusedDate,
                selectedDate: null,
                // Не используем для диапазона
                onDateSelected: (date) {},
                // Не используется для диапазона
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
                isRangeSelection: true,
                rangeStart: _rangeStart,
                rangeEnd: _rangeEnd,
                onRangeStartChanged: (date) {
                  setState(() {
                    _rangeStart = date;
                  });
                },
                onRangeEndChanged: (date) {
                  setState(() {
                    _rangeEnd = date;
                  });
                },
                rangeColor: Colors.blue[50]!,
                rangeStartColor: Colors.blue[400]!,
                rangeEndColor: Colors.blue[400]!,
                selectedColor: Colors.grey[600],
              ),
              AppSpacing.height24,
              // Информация о выбранном периоде
              if (_rangeStart != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выбранный период:',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      AppSpacing.height8,
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Начало:',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _rangeStart!
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_rangeEnd != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Конец:',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _rangeEnd!
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0],
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_rangeStart != null &&
                          _rangeEnd != null &&
                          _rangeStart?.compareTo(DateTime.now()
                                  .subtract(const Duration(days: 1))) !=
                              -1 &&
                          _rangeEnd?.compareTo(DateTime.now()
                                  .subtract(const Duration(days: 1))) !=
                              -1)
                      ? () {
                          Navigator.of(context).pop([_rangeStart!, _rangeEnd!]);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Сохранить'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
