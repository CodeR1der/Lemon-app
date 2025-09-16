import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_tracker/models/task_team.dart';
import 'package:task_tracker/services/project_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:task_tracker/widgets/common/app_common.dart';
import 'package:uuid/uuid.dart';

import '../models/employee.dart';
import '../models/priority.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'added_files_screen.dart';
import 'project_selection_screen.dart';

class TaskTitleScreen extends StatefulWidget {
  static const routeName = '/createTaskStart';
  static const screenName = '/TaskTitleScreen';

  final Employee? employee;
  final Project? project;

  const TaskTitleScreen({super.key, this.employee, this.project});

  @override
  _TaskTitleScreenState createState() => _TaskTitleScreenState();
}

class _TaskTitleScreenState extends State<TaskTitleScreen>
    with AutomaticKeepAliveClientMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isRecurring = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Предварительно фокусируемся на первом поле для плавной анимации клавиатуры
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_nameFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  // Фокус ноды для оптимизации анимаций клавиатуры
  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  void _navigateToNextScreen(Task task) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Скрываем клавиатуру перед навигацией
      FocusScope.of(context).unfocus();

      // Небольшая задержка для плавной анимации
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Логика навигации в зависимости от контекста
      if (widget.project != null) {
        // Если проект уже выбран, пропускаем экран выбора проекта
        task.project = widget.project!;
        // Обновляем команду проекта перед продолжением
        try {
          final latestTeam =
              await ProjectService().getProjectTeam(widget.project!.projectId);
          task.project!.team
            ..clear()
            ..addAll(latestTeam);
        } catch (_) {}
        await Get.to(() => AddedFilesScreen(task));
      } else {
        // Если проект не выбран, идем на экран выбора проекта
        await Get.to(() => ProjectSelectionScreen(
              task,
              preSelectedEmployee: widget.employee,
            ));
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Task _createTask() {
    return Task(
      id: const Uuid().v4(),
      taskName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      project: widget.project ??
          Project(
            projectId: 'default',
            name: 'Тестовый проект',
            team: [],
            companyId: UserService.to.currentUser!.companyId,
          ),
      team: TaskTeam.empty(),
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      priority: Priority.low,
      attachments: [],
      status: TaskStatus.newTask,
      companyId: UserService.to.currentUser!.companyId,
    );
  }

  void _handleNextPressed() {
    if (_isLoading) return;

    if (_formKey.currentState?.validate() ?? false) {
      final task = _createTask();
      _navigateToNextScreen(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Обязательно для корректной работы клавиатуры
      appBar: AppBar(
        title: const Text('Постановка задачи'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Название задачи', style: AppTextStyles.titleSmall),
              const SizedBox(height: 8),
              AppCommonWidgets.inputField(
                controller: _nameController,
                hintText: 'Название',
                validator: (value) =>
                    value!.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              Text('Описание задачи', style: AppTextStyles.titleSmall),
              const SizedBox(height: 8),
              AppCommonWidgets.inputField(
                controller: _descriptionController,
                hintText: 'Описание',
                validator: (value) =>
                    value!.isEmpty ? 'Введите описание' : null,
              ),
              const Spacer(),
              AppButtons.primaryButton(
                text: 'Дальше',
                onPressed: _isLoading ? () {} : _handleNextPressed,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
