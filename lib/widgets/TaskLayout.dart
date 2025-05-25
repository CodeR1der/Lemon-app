import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:task_tracker/models/task_validate.dart';
import 'package:task_tracker/screens/correction_screen.dart';
import 'package:task_tracker/screens/queue_screen.dart';
import 'package:task_tracker/screens/task_validate_screen.dart';
import 'package:task_tracker/services/request_operation.dart';
import 'package:task_tracker/widgets/revision_section.dart';

import '../models/correction.dart';
import '../models/task.dart';
import '../models/task_role.dart';
import '../models/task_status.dart';
import '../screens/task_history.dart';
import '../screens/task_validate_details_screen.dart';

class TaskLayoutBuilder extends StatelessWidget {
  final Task task;
  final TaskRole role;

  const TaskLayoutBuilder({
    super.key,
    required this.task,
    required this.role,
  });

  Future<List<Correction>> _loadCorrections() {
    final corrections = RequestService().getCorrection(task.id, task.status);

    return corrections;
  }

  Future<TaskValidate?> _loadValidates() {
    final validates = RequestService().getValidate(task.id, task.status);

    return validates;
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
      case TaskStatus.queue:
        return _buildQueueLayout(context);
      case TaskStatus.atWork:
        return _buildAtWorkLayout(context);
      case TaskStatus.extraTime:
        return _buildExtraTimeLayout(context);
      case TaskStatus.completedUnderReview:
        return _buildCompletedUnderReviewLayout(context);
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
                  RevisionsCard(
                      revisions: revisions,
                      task: task,
                      role: role,
                      title: 'Доработки и запросы')
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
                if (revisions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        task.changeStatus(TaskStatus.notRead);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey, width: 1),
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
                            'Принять',
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
                RevisionsCard(
                    revisions: revisions,
                    task: task,
                    role: role,
                    title: 'Доработки и запросы'),
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
                  RevisionsCard(
                      revisions: revisions,
                      task: task,
                      role: role,
                      title: 'Доработки и запросы'),
                ] else
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                  onTap: () {
                    // Действие при нажатии
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskHistoryScreen(revisions: revisions),
                      ),
                    );
                  },
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
                RevisionsCard(
                    revisions: revisions,
                    task: task,
                    role: role,
                    title: 'Доработки и запросы'),
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                  onTap: () {
                    // Действие при нажатии
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskHistoryScreen(revisions: revisions),
                      ),
                    );
                  },
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
                  onTap: () {
                    // Действие при нажатии
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskHistoryScreen(revisions: revisions),
                      ),
                    );
                  },
                ),
                const Divider(),
                RevisionsCard(
                    revisions: revisions,
                    task: task,
                    role: role,
                    title: 'Доработки и запросы'),
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
              return const Column();
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                const Divider(),
                if (revisions.isNotEmpty &&
                    revisions.any((revision) => !revision.isDone))
                  RevisionsCard(
                      revisions: revisions,
                      task: task,
                      role: role,
                      title: 'Доработки и запросы')
                else
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                Column(children: [
                  ElevatedButton(
                    onPressed: () {
                      RequestService()
                          .updateCorrection(notDoneRevision..isDone = true);

                      RequestService().addCorrection(Correction(
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
                RevisionsCard(
                    revisions: revisions,
                    task: task,
                    role: role,
                    title: 'Доработки и запросы'),
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
              return const Column();
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                const Divider(),
                _buildSectionItem(
                    icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                  onTap: () {
                    // Действие при нажатии
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskHistoryScreen(revisions: revisions),
                      ),
                    );
                  },
                ),
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildQueueLayout(BuildContext context) {
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
                  RevisionsCard(
                      revisions: revisions,
                      task: task,
                      role: role,
                      title: 'Доработки и запросы')
                else ...[
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                ],
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                  onTap: () {
                    // Действие при нажатии
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskHistoryScreen(revisions: revisions),
                      ),
                    );
                  },
                ),
              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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

          final notDoneRevisions = revisions.where((r) => !r.isDone).first;

          switch (role) {
            case TaskRole.executor:
              return Column(
                children: [
                  if (notDoneRevisions.status ==
                      TaskStatus.completedUnderReview)
                    RevisionsCard(
                        revisions: revisions,
                        task: task,
                        role: role,
                        title: 'Доработки и запросы')
                  else
                    _buildSectionItem(
                        icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskValidateScreen(task: task),
                        ),
                      );
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
                          'Сдать задачу на проверку',
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
                      task.changeStatus(TaskStatus.extraTime);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.orange, width: 1),
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
                          'Запросить дополнительное время',
                          style: TextStyle(
                            color: Colors.black, // Белый текст
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            case TaskRole.communicator:
              return Column(children: [
                _buildSectionItem(
                    icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                const Divider(),
                if (revisions.isNotEmpty &&
                    revisions.any((revision) => !revision.isDone))
                  RevisionsCard(
                      revisions: revisions,
                      task: task,
                      role: role,
                      title: 'Доработки и запросы')
                else ...[
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                ],
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                  onTap: () {
                    // Действие при нажатии
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskHistoryScreen(revisions: revisions),
                      ),
                    );
                  },
                ),
              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildExtraTimeLayout(BuildContext context) {
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
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
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
                  RevisionsCard(
                      revisions: revisions,
                      task: task,
                      role: role,
                      title: 'Доработки и запросы')
                else ...[
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                ],
                const Divider(),
                _buildSectionItem(
                  icon: Iconsax.clock_copy,
                  title: 'История задачи',
                  onTap: () {
                    // Действие при нажатии
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskHistoryScreen(revisions: revisions),
                      ),
                    );
                  },
                ),
              ]);
            case TaskRole.creator:
              return Column(
                children: [
                  _buildSectionItem(
                      icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                  const Divider(),
                  _buildSectionItem(
                    icon: Iconsax.clock_copy,
                    title: 'История задачи',
                    onTap: () {
                      // Действие при нажатии
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TaskHistoryScreen(revisions: revisions),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
              );
            case TaskRole.none:
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        });
  }

  Widget _buildCompletedUnderReviewLayout(BuildContext context) {
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

          return FutureBuilder<TaskValidate?>(
            future: RequestService().getValidate(task.id, task.status),
            builder: (context, validateSnapshot) {
              if (validateSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final validate = validateSnapshot.data;

              switch (role) {
                case TaskRole.executor:
                  return Column(
                    children: [
                      _buildSectionItem(
                          icon: Iconsax.edit_copy,
                          title: 'Доработки и запросы'),
                      const Divider(),
                      _buildSectionItem(
                        icon: Iconsax.clock_copy,
                        title: 'История задачи',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskHistoryScreen(revisions: revisions),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                  );
                case TaskRole.communicator:
                  return Column(children: [
                    _buildSectionItem(
                        icon: Iconsax.clock_copy, title: 'Контрольные точки'),
                    const Divider(),
                    _buildSectionItem(
                        icon: Iconsax.edit_copy, title: 'Доработки и запросы'),
                    const Divider(),
                    _buildSectionItem(
                      icon: Iconsax.clock_copy,
                      title: 'История задачи',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskHistoryScreen(revisions: revisions),
                          ),
                        );
                      },
                    ),
                  ]);
                case TaskRole.creator:
                  return Column(
                    children: [
                      _buildSectionItem(
                          icon: Iconsax.edit_copy,
                          title: 'Доработки и запросы'),
                      const Divider(),
                      _buildSectionItem(
                        icon: Iconsax.clock_copy,
                        title: 'История задачи',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskHistoryScreen(revisions: revisions),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TaskValidateDetailsScreen(
                                          task: task, validate: validate!)));
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
                              'Принять',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                case TaskRole.none:
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
            },
          );
        });
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
    VoidCallback? onTap, // Добавляем параметр для обработки нажатия
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: title == 'История задачи' ? onTap : null,
      // Делаем кликабельным только "Историю"
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF6D7885)),
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
            if (title == 'История задачи')
              const Icon(
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
