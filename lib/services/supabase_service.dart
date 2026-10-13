import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';
import '../models/permission_model.dart';
import '../supabase_options.dart';

/// Dịch vụ kết nối và thao tác với Supabase Database
/// Hỗ trợ tìm kiếm, cập nhật, phân quyền RLS và chia sẻ tài liệu
class SupabaseService {
  SupabaseClient? get _client {
    try {
      if (!SupabaseOptions.isConfigured) return null;
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('Supabase chưa khởi tạo: $e');
      return null;
    }
  }

  /// Khởi tạo Supabase SDK (gọi từ main.dart)
  static Future<void> initialize() async {
    if (!SupabaseOptions.isConfigured) {
      debugPrint('Supabase chưa có URL/Key hợp lệ. Đang dùng chế độ Demo Mock.');
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseOptions.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseOptions.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Lỗi khởi tạo Supabase.initialize: $e');
    }
  }

  /// Đồng bộ hồ sơ người dùng Firebase lên bảng profiles Supabase
  /// Gọi sau khi đăng nhập thành công để đảm bảo người dùng tồn tại trong DB
  Future<void> upsertProfile({
    required String uid,
    required String email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('profiles').upsert(
        {
          'id': uid,
          'email': email.trim().toLowerCase(),
          'display_name': displayName,
          'avatar_url': avatarUrl,
        },
        onConflict: 'id',
      );
      debugPrint('Profile đồng bộ lên Supabase: $email');
    } catch (e) {
      debugPrint('Lỗi upsertProfile Supabase: $e');
    }
  }

  /// Tìm kiếm người dùng theo email (dùng khi chia sẻ tài liệu)
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    final client = _client;
    if (client == null) return null;
    try {
      return await client
          .from('profiles')
          .select('id, email, display_name, avatar_url')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
    } catch (e) {
      debugPrint('Lỗi searchUserByEmail: $e');
      return null;
    }
  }

  /// Dữ liệu bộ nhớ tạm Mock khi chạy Offline hoặc chưa kết nối Supabase
  static final List<DocumentModel> _mockCloudDocs = [];
  static final List<PermissionModel> _mockPermissions = [];

  // ===========================================================================
  // 1. TÌM KIẾM VÀ TRUY VẤN TÀI LIỆU (DOCUMENTS)
  // ===========================================================================

  /// Lấy danh sách tài liệu người khác đã chia sẻ cho mình (grantee = userId)
  /// Đây là query chính để hiển thị tab "Được chia sẻ"
  Future<List<DocumentModel>> getSharedWithMe({required String userId}) async {
    final client = _client;
    if (client == null) return [];

    try {
      // Query document_permissions → join documents để lấy toàn bộ thông tin
      final List<dynamic> response = await client
          .from('document_permissions')
          .select('''
            permission_level,
            documents (
              id,
              owner_id,
              course_id,
              title,
              description,
              document_type,
              status,
              priority,
              file_url,
              storage_path,
              file_name,
              file_size,
              page_count,
              estimated_minutes,
              is_pinned,
              tags,
              due_date,
              completed_date,
              created_at
            )
          ''')
          .eq('grantee_id', userId)
          .not('documents', 'is', null); // Chỉ lấy permission có document tồn tại

      final List<DocumentModel> result = [];
      for (final item in response) {
        try {
          final docData = item['documents'] as Map<String, dynamic>?;
          if (docData == null) continue;
          final map = Map<String, dynamic>.from(docData);
          map['sharedPermission'] = item['permission_level']?.toString() ?? 'viewer';
          result.add(DocumentModel.fromMap(map));
        } catch (e) {
          debugPrint('Lỗi parse shared document: $e');
        }
      }
      return result;
    } catch (e) {
      debugPrint('Lỗi getSharedWithMe: $e');
      return [];
    }
  }

  /// Tìm kiếm tài liệu trên Supabase kết hợp lọc môn học và quyền chia sẻ
  Future<List<DocumentModel>> searchDocuments({
    String query = '',
    String? courseId,
    String? documentType,
    bool onlyShared = false,
    String? currentUserId,
  }) async {
    final client = _client;

    // Chế độ kết nối thực tế Supabase
    if (client != null) {
      try {
        var req = client.from('documents').select('''
          *,
          document_permissions (
            grantee_id,
            permission_level
          )
        ''');

        if (courseId != null && courseId.isNotEmpty && courseId != 'all') {
          req = req.eq('course_id', courseId);
        }

        if (documentType != null && documentType.isNotEmpty && documentType != 'all') {
          req = req.eq('document_type', documentType);
        }

        if (query.trim().isNotEmpty) {
          req = req.or('title.ilike.%${query.trim()}%,description.ilike.%${query.trim()}%');
        }

        final List<dynamic> response = await req.order('created_at', ascending: false);

        return response.map((data) {
          final map = Map<String, dynamic>.from(data as Map);
          String? userPermission = 'owner';
          if (currentUserId != null && map['owner_id'] != currentUserId) {
            final perms = map['document_permissions'] as List?;
            if (perms != null && perms.isNotEmpty) {
              userPermission = perms.first['permission_level']?.toString() ?? 'viewer';
            } else {
              userPermission = 'viewer';
            }
          }
          map['sharedPermission'] = userPermission;
          return DocumentModel.fromMap(map);
        }).toList();
      } catch (e) {
        debugPrint('Lỗi truy vấn Supabase searchDocuments: $e');
      }
    }

    // Chế độ dự phòng Mock Offline
    return _mockCloudDocs.where((doc) {
      final matchesQuery = query.isEmpty ||
          doc.title.toLowerCase().contains(query.toLowerCase()) ||
          doc.description.toLowerCase().contains(query.toLowerCase());
      final matchesCourse = courseId == null || courseId == 'all' || doc.courseId == courseId;
      final matchesType = documentType == null || documentType == 'all' || doc.type.name == documentType;
      final matchesShared = !onlyShared || (doc.sharedPermission != null && doc.sharedPermission != 'owner');
      return matchesQuery && matchesCourse && matchesType && matchesShared;
    }).toList();
  }

  // ===========================================================================
  // 2. THÊM MỚI VÀ CẬP NHẬT TÀI LIỆU
  // ===========================================================================

  /// Tạo mới tài liệu trên Supabase
  Future<DocumentModel> createDocument(DocumentModel doc, {required String userId}) async {
    final client = _client;
    final docWithOwner = doc.copyWith(ownerId: userId, sharedPermission: 'owner');

    if (client != null) {
      try {
        final payload = {
          'id': doc.id,
          'owner_id': userId,
          'course_id': doc.courseId,
          'title': doc.title,
          'description': doc.description,
          'document_type': doc.type.name,
          'status': doc.status.name,
          'priority': doc.priority.name,
          'file_url': doc.fileUrl,
          'storage_path': doc.storagePath,
          'file_name': doc.fileName,
          'file_size': doc.fileSize,
          'page_count': doc.pageCount,
          'estimated_minutes': doc.estimatedMinutes,
          'is_pinned': doc.isPinned,
          'tags': doc.tags,
          'due_date': doc.dueDate?.toIso8601String(),
          'completed_date': doc.completedDate?.toIso8601String(),
        };

        final response = await client.from('documents').insert(payload).select().single();
        return DocumentModel.fromMap(Map<String, dynamic>.from(response));
      } catch (e) {
        debugPrint('Lỗi tạo tài liệu Supabase: $e');
      }
    }

    _mockCloudDocs.removeWhere((d) => d.id == doc.id);
    _mockCloudDocs.insert(0, docWithOwner);
    return docWithOwner;
  }

  /// Cập nhật thông tin tài liệu trên Supabase (Hỗ trợ phân quyền Editor/Owner)
  Future<DocumentModel> updateDocument(DocumentModel doc) async {
    final client = _client;

    if (client != null) {
      try {
        final payload = {
          'title': doc.title,
          'description': doc.description,
          'course_id': doc.courseId,
          'document_type': doc.type.name,
          'status': doc.status.name,
          'priority': doc.priority.name,
          'file_url': doc.fileUrl,
          'storage_path': doc.storagePath,
          'file_name': doc.fileName,
          'file_size': doc.fileSize,
          'page_count': doc.pageCount,
          'estimated_minutes': doc.estimatedMinutes,
          'is_pinned': doc.isPinned,
          'tags': doc.tags,
          'due_date': doc.dueDate?.toIso8601String(),
          'completed_date': doc.completedDate?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await client.from('documents').update(payload).eq('id', doc.id).select().single();
        return DocumentModel.fromMap(Map<String, dynamic>.from(response));
      } catch (e) {
        debugPrint('Lỗi cập nhật tài liệu Supabase: $e');
      }
    }

    final index = _mockCloudDocs.indexWhere((d) => d.id == doc.id);
    if (index >= 0) {
      _mockCloudDocs[index] = doc;
    } else {
      _mockCloudDocs.add(doc);
    }
    return doc;
  }

  /// Xóa tài liệu trên Supabase
  Future<void> deleteDocument(String documentId) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('documents').delete().eq('id', documentId);
      } catch (e) {
        debugPrint('Lỗi xóa tài liệu Supabase: $e');
      }
    }
    _mockCloudDocs.removeWhere((d) => d.id == documentId);
    _mockPermissions.removeWhere((p) => p.documentId == documentId);
  }

  // ===========================================================================
  // 3. TÍNH NĂNG CHIA SẺ VÀ PHÂN QUYỀN (PERMISSIONS)
  // ===========================================================================

  /// Upsert tài liệu lên Supabase (tạo mới nếu chưa tồn tại, cập nhật nếu đã có)
  /// Cần gọi trước khi thêm permission để tránh lỗi foreign key constraint
  Future<void> upsertDocumentToCloud(DocumentModel doc, {required String ownerId}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('documents').upsert(
        {
          'id': doc.id,
          'owner_id': ownerId,
          'course_id': doc.courseId,
          'title': doc.title,
          'description': doc.description,
          'document_type': doc.type.name,
          'status': doc.status.name,
          'priority': doc.priority.name,
          'file_url': doc.fileUrl,
          'storage_path': doc.storagePath,
          'file_name': doc.fileName,
          'file_size': doc.fileSize,
          'page_count': doc.pageCount,
          'estimated_minutes': doc.estimatedMinutes,
          'is_pinned': doc.isPinned,
          'tags': doc.tags,
          'due_date': doc.dueDate?.toIso8601String(),
          'completed_date': doc.completedDate?.toIso8601String(),
        },
        onConflict: 'id',
      );
      debugPrint('Đã sync tài liệu "${doc.title}" lên Supabase (id: ${doc.id})');
    } catch (e) {
      debugPrint('Lỗi upsertDocumentToCloud: $e');
      rethrow;
    }
  }

  /// Chia sẻ tài liệu cho người dùng khác thông qua email
  /// [document] - Tài liệu cần chia sẻ (dùng để sync lên Supabase nếu chưa có)
  /// [ownerId] - Firebase UID của chủ sở hữu tài liệu
  Future<PermissionModel> shareDocument({
    required DocumentModel document,
    required String ownerId,
    required String granteeEmail,
    required String permissionLevel, // 'viewer' hoặc 'editor'
  }) async {
    final client = _client;

    if (client != null) {
      try {
        // Bước 0: Đảm bảo tài liệu tồn tại trên Supabase trước khi thêm permission
        // (Tránh lỗi foreign key: document_permissions_document_id_fkey)
        await upsertDocumentToCloud(document, ownerId: ownerId);

        // Bước 1: Tìm hồ sơ người dùng nhận quyền thông qua email
        final userProfile = await client
            .from('profiles')
            .select('id, email, display_name')
            .eq('email', granteeEmail.trim().toLowerCase())
            .maybeSingle();

        if (userProfile == null) {
          throw Exception(
            'Không tìm thấy người dùng với email "$granteeEmail".\n'
            'Người nhận cần đăng nhập vào app ít nhất 1 lần.',
          );
        }

        final granteeId = userProfile['id'].toString();

        // Bước 2: Thêm hoặc cập nhật bản ghi trong bảng document_permissions
        final payload = {
          'document_id': document.id,
          'grantee_id': granteeId,
          'permission_level': permissionLevel,
        };

        final response = await client
            .from('document_permissions')
            .upsert(payload, onConflict: 'document_id,grantee_id')
            .select('''
              id,
              document_id,
              grantee_id,
              permission_level,
              created_at,
              profiles:grantee_id (email, display_name)
            ''')
            .single();

        return PermissionModel.fromMap(Map<String, dynamic>.from(response));
      } catch (e) {
        debugPrint('Lỗi khi chia sẻ tài liệu Supabase: $e');
        rethrow;
      }
    }

    // Chế độ Mock cho phép kiểm thử tính năng chia sẻ ngay lập tức
    final mockPerm = PermissionModel(
      id: 'mock_perm_${DateTime.now().millisecondsSinceEpoch}',
      documentId: document.id,
      granteeId: 'mock_user_${granteeEmail.hashCode}',
      granteeEmail: granteeEmail,
      granteeName: granteeEmail.split('@').first,
      permissionLevel: permissionLevel,
      createdAt: DateTime.now(),
    );
    _mockPermissions.removeWhere((p) => p.documentId == document.id && p.granteeEmail == granteeEmail);
    _mockPermissions.add(mockPerm);
    return mockPerm;
  }

  /// Lấy danh sách các quyền đã chia sẻ cho một tài liệu cụ thể
  Future<List<PermissionModel>> getDocumentPermissions(String documentId) async {
    final client = _client;

    if (client != null) {
      try {
        final List<dynamic> response = await client
            .from('document_permissions')
            .select('''
              id,
              document_id,
              grantee_id,
              permission_level,
              created_at,
              profiles:grantee_id (email, display_name)
            ''')
            .eq('document_id', documentId)
            .order('created_at', ascending: true);

        return response
            .map((item) => PermissionModel.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (e) {
        debugPrint('Lỗi getDocumentPermissions: $e');
      }
    }

    return _mockPermissions.where((p) => p.documentId == documentId).toList();
  }

  /// Thu hồi quyền truy cập (Revoke permission)
  Future<void> revokePermission(String permissionId) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('document_permissions').delete().eq('id', permissionId);
      } catch (e) {
        debugPrint('Lỗi thu hồi quyền Supabase: $e');
      }
    }
    _mockPermissions.removeWhere((p) => p.id == permissionId);
  }
}
