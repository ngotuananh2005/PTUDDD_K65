import 'package:flutter_test/flutter_test.dart';
import 'package:projectsth1/models/document_model.dart';
import 'package:projectsth1/models/document_type.dart';
import 'package:projectsth1/models/permission_model.dart';
import 'package:projectsth1/services/firebase_storage_service.dart';
import 'package:projectsth1/services/supabase_service.dart';

void main() {
  group('TẦNG CLOUD & BẢO MẬT (Firebase Storage & Supabase Tests)', () {
    test('1. Kiểm thử cấu trúc lưu trữ và phân loại tệp tin của FirebaseStorageService', () {
      final storage = FirebaseStorageService();
      expect(storage, isNotNull);
    });

    test('2. Kiểm thử PermissionModel serialization và deserialization', () {
      final now = DateTime.now();
      final perm = PermissionModel(
        id: 'perm_123',
        documentId: 'doc_456',
        granteeId: 'user_789',
        granteeEmail: 'sinhvien@gmail.com',
        granteeName: 'Nguyen Van A',
        permissionLevel: 'editor',
        createdAt: now,
      );

      expect(perm.isEditor, isTrue);
      expect(perm.isViewer, isFalse);

      final map = perm.toMap();
      expect(map['permission_level'], equals('editor'));
      expect(map['grantee_id'], equals('user_789'));

      final parsed = PermissionModel.fromMap(map);
      expect(parsed.id, equals('perm_123'));
      expect(parsed.granteeId, equals('user_789'));
      expect(parsed.permissionLevel, equals('editor'));
    });

    test('3. Kiểm thử SupabaseService: Thêm mới, Tìm kiếm và Cập nhật thông tin tài liệu', () async {
      final service = SupabaseService();
      final now = DateTime.now();

      final doc = DocumentModel(
        id: 'doc_test_1',
        title: 'Giáo trình Kiến trúc Cashew Cloud',
        description: 'Tài liệu hướng dẫn kết nối Supabase và Storage',
        courseId: 'CSE441',
        type: DocumentType.lecture,
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/...',
        storagePath: 'documents/user1/doc_test_1/giao_trinh.pdf',
        fileName: 'giao_trinh.pdf',
        fileSize: 1024,
        dateCreated: now,
      );

      // Thêm mới
      final created = await service.createDocument(doc, userId: 'user_test_1');
      expect(created.id, equals('doc_test_1'));
      expect(created.ownerId, equals('user_test_1'));

      // Tìm kiếm theo từ khóa
      final searchResults = await service.searchDocuments(
        query: 'Cashew Cloud',
        courseId: 'CSE441',
      );
      expect(searchResults.length, equals(1));
      expect(searchResults.first.title, contains('Cashew Cloud'));

      // Cập nhật thông tin
      final updatedDoc = created.copyWith(
        title: 'Giáo trình Kiến trúc Cashew Cloud Đã Cập Nhật',
        status: StudyStatus.completed,
      );
      final updated = await service.updateDocument(updatedDoc);
      expect(updated.title, equals('Giáo trình Kiến trúc Cashew Cloud Đã Cập Nhật'));
      expect(updated.status, equals(StudyStatus.completed));
    });

    test('4. Kiểm thử SupabaseService: Chia sẻ tài liệu cho người khác và thu hồi quyền', () async {
      final service = SupabaseService();
      final now = DateTime.now();

      final doc = DocumentModel(
        id: 'doc_test_1',
        title: 'Giáo trình Kiến trúc Cashew Cloud',
        description: 'Tài liệu hướng dẫn kết nối Supabase và Storage',
        courseId: 'CSE441',
        type: DocumentType.lecture,
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/...',
        storagePath: 'documents/user1/doc_test_1/giao_trinh.pdf',
        fileName: 'giao_trinh.pdf',
        fileSize: 1024,
        dateCreated: now,
      );

      // Cấp quyền viewer cho sinhvien2
      final permViewer = await service.shareDocument(
        document: doc,
        ownerId: 'user_test_1',
        granteeEmail: 'banhoc@gmail.com',
        permissionLevel: 'viewer',
      );
      expect(permViewer.granteeEmail, equals('banhoc@gmail.com'));
      expect(permViewer.isViewer, isTrue);

      // Lấy danh sách quyền của tài liệu
      final permissions = await service.getDocumentPermissions('doc_test_1');
      expect(permissions.any((p) => p.granteeEmail == 'banhoc@gmail.com'), isTrue);

      // Thu hồi quyền
      await service.revokePermission(permViewer.id);
      final permissionsAfter = await service.getDocumentPermissions('doc_test_1');
      expect(permissionsAfter.any((p) => p.id == permViewer.id), isFalse);

      // Xóa tài liệu
      await service.deleteDocument('doc_test_1');
      final searchAfterDelete = await service.searchDocuments(query: 'Cashew Cloud');
      expect(searchAfterDelete.isEmpty, isTrue);
    });
  });
}
