class Announcement {
  late String id;
  final String title;
  final String fullText;
  final DateTime date;
  final List<String> readBy;
  List<String> attachments;
  late String companyId;
  // Новые поля
  final List<String> selectedEmployees; // Список выбранных сотрудников
  String status; // 'active', 'closed'

  Announcement({
    required this.id,
    required this.title,
    required this.fullText,
    required this.date,
    required this.attachments,
    required this.readBy,
    required this.companyId,
    required this.selectedEmployees,
    this.status = 'active',
  });

  int get readCount => readBy.length;

  Announcement copyWith({
    String? id,
    String? title,
    String? fullText,
    DateTime? date,
    List<String>? readBy,
    List<String>? attachments,
    String? companyId,
    List<String>? selectedEmployees,
    String? status,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      fullText: fullText ?? this.fullText,
      date: date ?? this.date,
      attachments: attachments ?? this.attachments,
      readBy: readBy ?? this.readBy,
      companyId: companyId ?? this.companyId,
      selectedEmployees: selectedEmployees ?? this.selectedEmployees,
      status: status ?? this.status,
    );
  }

  // Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'full_text': fullText,
      'created_at': date.toIso8601String(),
      'attachments': attachments,
      'read_by': readBy,
      'company_id': companyId,
      'selected_employees': selectedEmployees,
      'status': status,
    };
  }

  // Преобразование объекта в JSON без selected_employees (для основной таблицы)
  Map<String, dynamic> toJsonWithoutEmployees() {
    return {
      'id': id,
      'title': title,
      'full_text': fullText,
      'created_at': date.toIso8601String(),
      'attachments': attachments,
      'read_by': readBy,
      'company_id': companyId,
      'status': status,
    };
  }

  // Создание объекта из JSON
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      fullText: json['full_text'] as String,
      date: DateTime.parse(json['created_at'] as String),
      attachments: List<String>.from(json['attachments'] ?? []),
      readBy: List<String>.from(json['read_by'] as List<dynamic>),
      companyId: json['company_id'] as String,
      selectedEmployees: List<String>.from(json['selected_employees'] ?? []),
      status: json['status'] as String? ?? 'active',
    );
  }
}

// Модель для логов действий с объявлениями
class AnnouncementLog {
  final String id;
  final String action; // 'created', 'read', 'marked_read', 'closed'
  final String userId;
  final String userName;
  final String userRole;
  final DateTime timestamp;
  final String? targetUserId; // ID сотрудника, для которого выполнено действие
  final String?
      targetUserName; // Имя сотрудника, для которого выполнено действие
  final String? announcementId; // ID объявления
  final String companyId;

  AnnouncementLog({
    required this.id,
    required this.action,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.timestamp,
    required this.companyId,
    this.targetUserId,
    this.targetUserName,
    this.announcementId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'timestamp': timestamp.toIso8601String(),
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'announcement_id': announcementId,
      'company_id': companyId
    };
  }

  factory AnnouncementLog.fromJson(Map<String, dynamic> json) {
    return AnnouncementLog(
      id: json['id'] as String,
      action: json['action'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userRole: json['userRole'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      targetUserId: json['targetUserId'] as String?,
      targetUserName: json['targetUserName'] as String?,
      announcementId: json['announcement_id'] as String?,
      companyId: json['company_id'] as String,
    );
  }
}
