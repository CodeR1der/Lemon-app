import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/screens/correction_screen.dart';
import 'package:task_tracker/screens/queue_screen.dart';
import 'package:task_tracker/services/correction_operation.dart';
import 'package:task_tracker/widgets/revision_section.dart';

import '../models/correction.dart';
import '../models/task.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';

class TaskLayoutBuilder extends StatelessWidget {
  final Task task;
  final TaskRole role;

  const TaskLayoutBuilder({
    super.key,
    required this.task,
    required this.role,
  });

  Future<List<Correction>> _loadCorrections() {
    final corrections = CorrectionService().getCorrection(task.id, task.status);

    return corrections;
  }

  @override
  Widget build(BuildContext context) {
    switch (task.status) {
      case TaskStatus.newTask:
        return _buildNewTaskLayout(context);
      case TaskStatus.revision:
        return _buildRevisionLayout(context);
      case TaskStatus.notRead:
        return _buildNotReadLayout(context);
      case TaskStatus.needExplanation:
        return _buildNeedExplanationLayout(context);
      case TaskStatus.needTicket:
        return _buildNeedTicketLayout(context);
      case TaskStatus.inOrder:
        return _buildInOrderLayout(context);
      case TaskStatus.atWork:
        return _buildAtWorkLayout(context);
      case TaskStatus.overdue:
        return _buildOverdueLayout(context);
      case TaskStatus.completed:
        return _buildCompletedLayout(context);
      default:
        return _buildNewTaskLayout(context);
    }
  }

  Widget _buildNewTaskLayout(BuildContext context) {
    return FutureBuilder<List<Correction>>(
        future: _loadCorrections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final revisions = snapshot.data ?? [];

          switch (role) {
            case TaskRole.executor:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                      icon: Iconsax.clock_copy, title: 'История задачи'),
                  const Divider(),
                ],
              );
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                const Divider(),
                if (revisions.isNotEmpty &&
                    revisions.any((revision) => !revision.isDone))
                  RevisionsCard(revisions: revisions, task: task, role: role)
                else ...[
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CorrectionScreen(task: task),
                          ),
                        );
                        print('Жалоба на некорректную постановку задачи');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 8),
                          Text(
                            'Задача поставлена плохо / некорректно',
                            style: TextStyle(
                              color: Colors.white, // Белый текст
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'История задачи'),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      task.changeStatus(TaskStatus.notRead);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey, width: 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8),
                        Text(
                          'Выставить в очередь на выполнение',
                          style: TextStyle(
                            color: Colors.black, // Белый текст
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                      icon: Iconsax.clock_copy, title: 'История задачи'),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildRevisionLayout(BuildContext context) {
    return FutureBuilder<List<Correction>>(
      future: _loadCorrections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final revisions = snapshot.data ?? [];
        final notDoneRevision =
            revisions.where((revision) => !revision.isDone).first;

        switch (role) {
          case TaskRole.executor:
            return Column(
              children: [
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'Контрольные точки',
                ),
                const Divider(),
                RevisionsCard(revisions: revisions, task: task, role: role),
              ],
            );

          case TaskRole.communicator:
            return Column(
              children: [
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'Контрольные точки',
                ),
                const Divider(),
                if (notDoneRevision.status != TaskStatus.newTask) ...[
                  RevisionsCard(revisions: revisions, task: task, role: role),
                ] else
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                ),
              ],
            );

          case TaskRole.creator:
            return Column(
              children: [
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'Контрольные точки',
                ),
                const Divider(),
                RevisionsCard(revisions: revisions, task: task, role: role),
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                ),
                const Divider(),
              ],
            );

          case TaskRole.none:
            return Column(
              children: [
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                ),
                const Divider(),
                RevisionsCard(revisions: revisions, task: task, role: role),
              ],
            );
        }
      },
    );
  }

  Widget _buildNotReadLayout(BuildContext context) {
    return FutureBuilder<List<Correction>>(
        future: _loadCorrections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final revisions = snapshot.data ?? [];
          switch (role) {
            case TaskRole.executor:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                      icon: Iconsax.clock_copy, title: 'История задачи'),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        task.changeStatus(TaskStatus.inOrder);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 8),
                          Text(
                            'Прочитал и понял',
                            style: TextStyle(
                              color: Colors.white, // Белый текст
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CorrectionScreen(task: task),
                          ),
                        );
                        //task.changeStatus(TaskStatus.needExplanation);
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
                            'Нужно разъяснение',
                            style: TextStyle(
                              color: Colors.black, // Белый текст
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8),
                        Text(
                          'Напомнить прочитать',
                          style: TextStyle(
                            color: Colors.white, // Белый текст
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'История задачи'),
                const Divider(),
              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                      icon: Iconsax.clock_copy, title: 'История задачи'),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildNeedExplanationLayout(BuildContext context) {
    return FutureBuilder<List<Correction>>(
        future: _loadCorrections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final revisions = snapshot.data ?? [];
          final notDoneRevision =
              revisions.where((revision) => !revision.isDone).first;

          switch (role) {
            case TaskRole.executor:
              return Column();
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                const Divider(),
                if (revisions.isNotEmpty &&
                    revisions.any((revision) => !revision.isDone))
                  RevisionsCard(revisions: revisions, task: task, role: role)
                else
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                Column(children: [
                  ElevatedButton(
                    onPressed: () {
                      CorrectionService()
                          .updateCorrection(notDoneRevision..isDone = true);

                      CorrectionService().addCorrection(Correction(
                          date: DateTime.now(),
                          taskId: task.id,
                          status: TaskStatus.needExplanation,
                          description: 'Прислать письмо-решение'));

                      task.changeStatus(TaskStatus.needTicket);

                      print('Жалоба на некорректную постановку задачи');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8),
                        Text(
                          'Прислать письмо-решение',
                          style: TextStyle(
                            color: Colors.white, // Белый текст
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      task.changeStatus(TaskStatus.revision);
                      print('Жалоба на некорректную постановку задачи');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.orange, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 8),
                        Text(
                          'Отправить на доработку',
                          style: TextStyle(
                            color: Colors.black, // Белый текст
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'История задачи'),
                const Divider(),
              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                      icon: Iconsax.clock_copy, title: 'История задачи'),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildNeedTicketLayout(BuildContext context) {
    return FutureBuilder<List<Correction>>(
        future: _loadCorrections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final revisions = snapshot.data ?? [];
          final notDoneRevision =
              revisions.where((revision) => !revision.isDone).first;

          switch (role) {
            case TaskRole.executor:
              return Column(children: [
                RevisionsCard(revisions: revisions, task: task, role: role),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'История задачи'),
                const Divider(),
              ]);
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'История задачи'),
                const Divider(),
              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                      icon: Iconsax.clock_copy, title: 'История задачи'),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildInOrderLayout(BuildContext context) {
    return FutureBuilder<List<Correction>>(
        future: _loadCorrections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final revisions = snapshot.data ?? [];


          switch (role) {
            case TaskRole.executor:
              return Column();
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'История задачи'),
                const Divider(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QueueScreen(task: task),
                      ),
                    );
                    print('Жалоба на некорректную постановку задачи');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 8),
                      Text(
                        'Выставить в очередь',
                        style: TextStyle(
                          color: Colors.white, // Белый текст
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                      icon: Iconsax.clock_copy, title: 'История задачи'),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildAtWorkLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context),
    );
  }

  Widget _buildOverdueLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context, warning: true),
    );
  }

  Widget _buildCompletedLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
        ),
      ),
      child: _buildCommonLayout(context),
    );
  }

  Widget _buildCommonLayout(BuildContext context, {bool warning = false}) {
    return Column(
      children: [
        if (warning)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.withOpacity(0.2),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Срочно! Требуется ваше внимание!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        // Здесь будет ваш основной контент
      ],
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Color(0xFF6D7885)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            if (title == 'История задачи')
              Icon(
                Icons.chevron_right,
                size: 24,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }
}
