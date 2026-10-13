/// Model đại diện cho một bản ghi quyền chia sẻ trong bảng document_permissions
class PermissionModel {
  final String id;
  final String documentId;
  final String granteeId;
  final String granteeEmail;
  final String granteeName;
  final String permissionLevel; // 'viewer' hoặc 'editor'
  final DateTime createdAt;

  const PermissionModel({
    required this.id,
    required this.documentId,
    required this.granteeId,
    required this.granteeEmail,
    this.granteeName = '',
    required this.permissionLevel,
    required this.createdAt,
  });

  bool get isEditor => permissionLevel == 'editor';
  bool get isViewer => permissionLevel == 'viewer';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'grantee_id': granteeId,
      'permission_level': permissionLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    return PermissionModel(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      granteeId: map['grantee_id']?.toString() ?? '',
      granteeEmail: map['grantee_email']?.toString() ?? map['profiles']?['email']?.toString() ?? '',
      granteeName: map['grantee_name']?.toString() ?? map['profiles']?['display_name']?.toString() ?? '',
      permissionLevel: map['permission_level']?.toString() ?? 'viewer',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
