import '../../../models/task_status.dart';
import '../interfaces/task_layout_strategy.dart';
import '../layouts/at_work_layout.dart';
import '../layouts/completed_layout.dart';
import '../layouts/completed_under_review_layout.dart';
import '../layouts/control_point_layout.dart';
import '../layouts/extra_time_layout.dart';
import '../layouts/in_order_layout.dart';
import '../layouts/need_explanation_layout.dart';
import '../layouts/need_ticket_layout.dart';
import '../layouts/new_task_layout.dart';
import '../layouts/not_read_layout.dart';
import '../layouts/overdue_layout.dart';
import '../layouts/queue_layout.dart';
import '../layouts/revision_layout.dart';


class TaskLayoutFactory {
  static TaskLayoutStrategy getStrategy(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return NewTaskLayoutStrategy();
      case TaskStatus.revision:
        return RevisionLayoutStrategy();
      case TaskStatus.notRead:
        return NotReadLayoutStrategy();
      case TaskStatus.needExplanation:
        return NeedExplanationLayoutStrategy();
      case TaskStatus.needTicket:
        return NeedTicketLayoutStrategy();
      case TaskStatus.inOrder:
        return InOrderLayoutStrategy();
      case TaskStatus.queue:
        return QueueLayoutStrategy();
      case TaskStatus.atWork:
        return AtWorkLayoutStrategy();
      case TaskStatus.controlPoint:
        return ControlPointLayoutStrategy();
      case TaskStatus.extraTime:
        return ExtraTimeLayoutStrategy();
      case TaskStatus.completedUnderReview:
        return CompletedUnderReviewLayoutStrategy();
      case TaskStatus.completed:
        return CompletedLayoutStrategy();
      case TaskStatus.overdue:
        return OverdueLayoutStrategy();
      default:
        return NewTaskLayoutStrategy();
    }
  }
}
