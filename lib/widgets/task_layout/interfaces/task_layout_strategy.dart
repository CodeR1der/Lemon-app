import 'package:flutter/material.dart';

import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';

// Strategy interface for different task layouts
abstract class TaskLayoutStrategy {
  Widget buildLayout(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions);
}
