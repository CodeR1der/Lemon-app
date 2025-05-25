import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker/models/correction.dart';
import 'package:task_tracker/models/task_role.dart';
import 'package:task_tracker/models/task_status.dart';
import 'package:task_tracker/screens/correction_details_screen.dart';
import 'package:task_tracker/screens/correction_screen.dart';

import '../models/task.dart';

class RevisionsCard extends StatelessWidget {
  final List<Correction> revisions;
  final Task task;
  final TaskRole role;
  final String title;

  const RevisionsCard(
      {super.key,
      required this.revisions,
      required this.task,
      required this.role,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (title == "Доработки и запросы")
        InkWell(
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                const Icon(Iconsax.edit_copy,
                    size: 24, color: Color(0xFF6D7885)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (revisions.isNotEmpty)
        Card(
          color: Colors.white,
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Список доработок
                ...revisions
                    .where((revision) => !revision
                        .isDone) // Фильтруем только невыполненные ревизии
                    .map((revision) => _buildRevisionItem(context, revision))
                    .toList(),
              ],
            ),
          ),
        )
    ]);
  }

  Widget _buildRevisionItem(BuildContext context, Correction correction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Дата создания
        Text(
          DateFormat('dd.MM.yyyy').format(correction.date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black,
              ),
        ),
        const SizedBox(height: 4),

        if (role != TaskRole.executor) ...[
          Text(
            _getActionTitle(correction.status),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 4),
        ],
        // Описание доработки
        Text(
          correction.description!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
              ),
        ),

        if (task.status == TaskStatus.needExplanation)
          ...[]
        else if (task.status == TaskStatus.needTicket) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showRevisionDetails(context, correction),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CorrectionScreen(
                                task: task, prevCorrection: correction),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // закругление углов
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 8),
                          Text(
                            'Написать письмо-решение',
                            style: TextStyle(
                              color: Colors.white, // Белый текст
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.blue, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // закругление углов
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Icon(Iconsax.info_circle,
                                color: Colors.blue, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Как написать письмо-решение',
                              style: TextStyle(
                                color: Colors.blue, // Белый текст
                                fontSize: 16,
                              ),
                            ),
                          ])
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Кнопка "Подробнее"
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showRevisionDetails(context, correction),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CorrectionDetailsScreen(
                          correction: correction,
                          task: task,
                          role: role,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.orange, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // закругление углов
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 8),
                      Text(
                        'Подробнее',
                        style: TextStyle(
                          color: Colors.black, // Белый текст
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // Разделитель (кроме последнего элемента)
        if (correction != revisions.last) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _showRevisionDetails(BuildContext context, Correction correction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Подробности доработки',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Детали
              _buildDetailRow(context, 'Дата создания:',
                  DateFormat('dd.MM.yyyy HH:mm').format(correction.date)),

              const SizedBox(height: 12),
              _buildDetailRow(context, 'Описание:', correction.description!),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _getActionTitle(TaskStatus status) {
    switch (status) {
      case TaskStatus.atWork:
        return 'Запрос на дополнительное время';
      case TaskStatus.newTask:
        return 'Описание ошибок в поставке задачи';
      case TaskStatus.notRead:
        return 'Причина разъяснения';
      case TaskStatus.needTicket:
        return 'Письмо-решение';
      // Добавьте другие статусы по необходимости
      default:
        return 'Изменение статуса';
    }
  }
}
