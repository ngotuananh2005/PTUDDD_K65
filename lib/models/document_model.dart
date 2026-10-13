import 'document_type.dart';

/// Entity đại diện cho một Tài liệu học tập (Tương đương Transaction/Objective trong Cashew)
/// Hỗ trợ cả lưu trữ cục bộ (SQLite / SharedPreferences) và Cloud (Supabase / Firebase Storage)
class DocumentModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final DocumentType type;
  final StudyStatus status;
  final PriorityLevel priority;
  final String fileUrl; // Đường dẫn URL tải từ Firebase Storage hoặc file đính kèm
  final String storagePath; // Đường dẫn file trên Firebase Storage: documents/{userId}/{docId}/{fileName}
  final String fileName; // Tên gốc của tệp đính kèm
  final int fileSize; // Dung lượng tệp (bytes)
  final String? ownerId; // ID người sở hữu trên Supabase / Firebase Auth
  final String? ownerEmail; // Email người sở hữu
  final String? sharedPermission; // Quyền truy cập: 'owner', 'editor', 'viewer'
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
    this.storagePath = '',
    this.fileName = '',
    this.fileSize = 0,
    this.ownerId,
    this.ownerEmail,
    this.sharedPermission,
    this.pageCount = 0,
    this.estimatedMinutes = 30,
    this.isPinned = false,
    required this.dateCreated,
    this.dueDate,
    this.completedDate,
    this.tags = const [],
  });

  /// Người dùng hiện tại có phải chủ sở hữu tài liệu hay không
  bool get isOwner => sharedPermission == null || sharedPermission == 'owner';

  /// Người dùng hiện tại có quyền sửa đổi tài liệu hay không (Owner hoặc Editor)
  bool get canEdit => isOwner || sharedPermission == 'editor';

  /// Tài liệu có đính kèm file Cloud hay không
  bool get hasFile => fileUrl.isNotEmpty;

  DocumentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    DocumentType? type,
    StudyStatus? status,
    PriorityLevel? priority,
    String? fileUrl,
    String? storagePath,
    String? fileName,
    int? fileSize,
    String? ownerId,
    String? ownerEmail,
    String? sharedPermission,
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
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      sharedPermission: sharedPermission ?? this.sharedPermission,
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
      'storagePath': storagePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'sharedPermission': sharedPermission,
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
    // Hỗ trợ cả key kiểu camelCase (SQLite local) và snake_case (Supabase)
    String strOf(String camel, String snake) =>
        (map[camel] ?? map[snake] ?? '').toString();
    int intOf(String camel, String snake, [int def = 0]) =>
        (map[camel] ?? map[snake] as int?) ?? def;

    final createdAtRaw = map['dateCreated'] ?? map['created_at'];
    final dueDateRaw = map['dueDate'] ?? map['due_date'];
    final completedRaw = map['completedDate'] ?? map['completed_date'];
    final typeRaw = map['type'] ?? map['document_type'];
    final statusRaw = map['status'];
    final priorityRaw = map['priority'];
    final courseRaw = map['courseId'] ?? map['course_id'] ?? '';
    final isPinnedRaw = map['isPinned'] ?? map['is_pinned'];
    final tagsRaw = map['tags'];
    final fileSizeRaw = map['fileSize'] ?? map['file_size'];

    return DocumentModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: (map['description'] as String?) ?? '',
      courseId: courseRaw.toString(),
      type: DocumentType.fromString(typeRaw?.toString()),
      status: StudyStatus.fromString(statusRaw?.toString()),
      priority: PriorityLevel.fromString(priorityRaw?.toString()),
      fileUrl: strOf('fileUrl', 'file_url'),
      storagePath: strOf('storagePath', 'storage_path'),
      fileName: strOf('fileName', 'file_name'),
      fileSize: (fileSizeRaw is int) ? fileSizeRaw : int.tryParse(fileSizeRaw?.toString() ?? '0') ?? 0,
      ownerId: (map['ownerId'] ?? map['owner_id'])?.toString(),
      ownerEmail: map['ownerEmail']?.toString() ?? map['ownerEmail']?.toString(),
      sharedPermission: map['sharedPermission']?.toString(),
      pageCount: intOf('pageCount', 'page_count', 0),
      estimatedMinutes: intOf('estimatedMinutes', 'estimated_minutes', 30),
      isPinned: (isPinnedRaw == 1 || isPinnedRaw == true),
      dateCreated: createdAtRaw != null
          ? (createdAtRaw is DateTime ? createdAtRaw : DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now())
          : DateTime.now(),
      dueDate: dueDateRaw != null ? DateTime.tryParse(dueDateRaw.toString()) : null,
      completedDate: completedRaw != null ? DateTime.tryParse(completedRaw.toString()) : null,
      tags: tagsRaw is List
          ? (tagsRaw).map((t) => t.toString()).where((t) => t.trim().isNotEmpty).toList()
          : (tagsRaw?.toString().split(',').where((t) => t.trim().isNotEmpty).toList() ?? []),
    );
  }

}
