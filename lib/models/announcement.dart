class Announcement {
  late String id;
  final String title;
  final String fullText;
  final DateTime date;
  final List<String> readBy;
  List<String> attachments;
  late String companyId;

  Announcement({
    required this.id,
    required this.title,
    required this.fullText,
    required this.date,
    required this.attachments,
    required this.readBy,
    required this.companyId,
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
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      fullText: fullText ?? this.fullText,
      date: date ?? this.date,
      attachments: attachments ?? this.attachments,
      readBy: readBy ?? this.readBy,
      companyId: companyId ?? this.companyId,
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
    );
  }
}