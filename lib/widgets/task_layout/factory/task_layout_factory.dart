import '../../../models/task_status.dart';
import '../interfaces/task_layout_strategy.dart';
import '../strategies/at_work_layout.dart';
import '../strategies/completed_under_review_layout.dart';
import '../strategies/control_point_layout.dart';
import '../strategies/extra_time_layout.dart';
import '../strategies/in_order_layout.dart';
import '../strategies/need_explanation_layout.dart';
import '../strategies/need_ticket_layout.dart';
import '../strategies/new_task_layout.dart';
import '../strategies/not_read_layout.dart';
import '../strategies/overdue_layout.dart';
import '../strategies/queue_layout.dart';
import '../strategies/remaining_strategies.dart';
import '../strategies/revision_layout.dart';

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
