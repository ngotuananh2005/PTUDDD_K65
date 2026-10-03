import 'document_type.dart';

/// Entity đại diện cho một Tài liệu học tập (Tương đương Transaction/Objective trong Cashew)
class DocumentModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final DocumentType type;
  final StudyStatus status;
  final PriorityLevel priority;
  final String fileUrl; // Đường dẫn URL hoặc file đính kèm
  final int pageCount; // Số trang
  final int estimatedMinutes; // Thời gian ước lượng để đọc/làm
  final bool isPinned; // Ghim lên đầu / Yêu thích
  final DateTime dateCreated;
  final DateTime? dueDate; // Hạn chót nếu là bài tập
  final DateTime? completedDate;
  final List<String> tags;

  const DocumentModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.courseId,
    required this.type,
    this.status = StudyStatus.pending,
    this.priority = PriorityLevel.medium,
    this.fileUrl = '',
    this.pageCount = 0,
    this.estimatedMinutes = 30,
    this.isPinned = false,
    required this.dateCreated,
    this.dueDate,
    this.completedDate,
    this.tags = const [],
  });

  DocumentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    DocumentType? type,
    StudyStatus? status,
    PriorityLevel? priority,
    String? fileUrl,
    int? pageCount,
    int? estimatedMinutes,
    bool? isPinned,
    DateTime? dateCreated,
    DateTime? dueDate,
    DateTime? completedDate,
    List<String>? tags,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      fileUrl: fileUrl ?? this.fileUrl,
      pageCount: pageCount ?? this.pageCount,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isPinned: isPinned ?? this.isPinned,
      dateCreated: dateCreated ?? this.dateCreated,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'courseId': courseId,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'fileUrl': fileUrl,
      'pageCount': pageCount,
      'estimatedMinutes': estimatedMinutes,
      'isPinned': isPinned ? 1 : 0,
      'dateCreated': dateCreated.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'tags': tags.join(','),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      courseId: map['courseId'] as String,
      type: DocumentType.fromString(map['type'] as String?),
      status: StudyStatus.fromString(map['status'] as String?),
      priority: PriorityLevel.fromString(map['priority'] as String?),
      fileUrl: (map['fileUrl'] as String?) ?? '',
      pageCount: (map['pageCount'] as int?) ?? 0,
      estimatedMinutes: (map['estimatedMinutes'] as int?) ?? 30,
      isPinned: (map['isPinned'] == 1 || map['isPinned'] == true),
      dateCreated: DateTime.parse(map['dateCreated'] as String),
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'] as String) : null,
      completedDate: map['completedDate'] != null ? DateTime.tryParse(map['completedDate'] as String) : null,
      tags: map['tags'] is List
          ? (map['tags'] as List).map((t) => t.toString()).where((t) => t.trim().isNotEmpty).toList()
          : ((map['tags'] as String?)?.split(',').where((t) => t.trim().isNotEmpty).toList() ?? []),
    );
  }
}
