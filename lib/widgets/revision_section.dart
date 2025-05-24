import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker/models/correction.dart';
import 'package:task_tracker/screens/correction_details_screen.dart';

import '../models/task.dart';
import '../screens/correction_screen.dart';

class RevisionsCard extends StatelessWidget {
  final List<Correction> revisions;
  final Task task;

  const RevisionsCard({super.key, required this.revisions, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Icon(Iconsax.edit_copy, size: 24, color: Color(0xFF6D7885)),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Доработки и запросы",
                  style: TextStyle(
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Дата создания
        Text(
          DateFormat('dd.MM.yyyy').format(correction.date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black,
              ),
        ),
        const SizedBox(height: 4),

        Text(
          'Описание ошибок в постановке задачи',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 4),
        // Описание доработки
        Text(
          correction.description!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
              ),
        ),

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
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CorrectionDetailsScreen(correction: correction, task: task),
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
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
}
