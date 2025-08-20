import 'package:flutter/material.dart';

import '../../../models/control_point.dart';
import '../../../models/correction.dart';
import '../../../models/task.dart';
import '../../../models/task_role.dart';
import '../base/base_task_layout_strategy.dart';

class CompletedLayoutStrategy extends BaseTaskLayoutStrategy {
  @override
  Widget buildLayout(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
        ),
      ),
      child: super.buildLayout(context, task, role, revisions, controlPoints),
    );
  }
//
  @override
  List<Widget> buildSections(BuildContext context, Task task, TaskRole role,
      List<Correction> revisions, List<ControlPoint> controlPoints) {
    // Implement completed task layout
    return [
       buildHistorySection(context, revisions),
    ];
  }
}
