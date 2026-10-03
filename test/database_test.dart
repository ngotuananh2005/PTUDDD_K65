import 'package:flutter_test/flutter_test.dart';
import 'package:projectsth1/database/app_database.dart';
import 'package:projectsth1/models/document_model.dart';
import 'package:projectsth1/models/document_type.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TẦNG DỮ LIỆU (Data Layer / Database DAO Tests)', () {
    late StudyAppDatabase database;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      database = StudyAppDatabase();
    });

    test('1. Khởi tạo CSDL có sẵn dữ liệu mẫu ban đầu', () {
      final docs = database.getAllDocuments();
      final courses = database.getAllCourses();

      expect(docs.isNotEmpty, true, reason: 'Danh sách tài liệu ban đầu không được rỗng');
      expect(courses.isNotEmpty, true, reason: 'Danh sách môn học ban đầu không được rỗng');
      expect(courses.any((c) => c.code == 'CSE441'), true);
    });

    test('2. Thêm mới tài liệu và truy vấn lại chính xác (Create & Read)', () async {
      final newDoc = DocumentModel(
        id: 'test_doc_99',
        title: 'Tài liệu Kiểm thử Đơn vị',
        description: 'Mô tả kiểm thử cho tầng dữ liệu',
        courseId: 'course_cse441',
        type: DocumentType.lecture,
        status: StudyStatus.pending,
        priority: PriorityLevel.high,
        estimatedMinutes: 45,
        dateCreated: DateTime.now(),
        tags: const ['Unit', 'Test'],
      );

      await database.createOrUpdateDocument(newDoc);

      final fetchedDoc = database.getDocumentById('test_doc_99');
      expect(fetchedDoc, isNotNull);
      expect(fetchedDoc!.title, 'Tài liệu Kiểm thử Đơn vị');
      expect(fetchedDoc.courseId, 'course_cse441');
      expect(fetchedDoc.type, DocumentType.lecture);
    });

    test('3. Cập nhật trạng thái tài liệu (Update)', () async {
      const docId = 'test_doc_99';
      await database.updateDocumentStatus(docId, StudyStatus.completed);

      final updatedDoc = database.getDocumentById(docId);
      expect(updatedDoc?.status, StudyStatus.completed);
      expect(updatedDoc?.completedDate, isNotNull);
    });

    test('4. Tìm kiếm và lọc đa tiêu chí (Search & Filter)', () {
      final results = database.searchAndFilterDocuments(
        query: 'Kiểm thử',
        courseId: 'course_cse441',
      );

      expect(results.length, 1);
      expect(results.first.id, 'test_doc_99');
    });

    test('5. Xóa tài liệu khỏi CSDL (Delete)', () async {
      const docId = 'test_doc_99';
      final isDeleted = await database.deleteDocument(docId);

      expect(isDeleted, true);
      expect(database.getDocumentById(docId), isNull);
    });

    test('6. Kiểm tra cơ chế Phản ứng (Reactive Stream watchAllDocuments)', () async {
      final stream = database.watchAllDocuments();

      final firstEvent = await stream.first;
      expect(firstEvent.isNotEmpty, true);
    });

    test('7. Lưu trữ cục bộ vĩnh viễn (Persistence across restarts)', () async {
      final doc = DocumentModel(
        id: 'persistent_doc_1',
        title: 'Tài liệu Lưu trữ vĩnh viễn',
        courseId: 'course_cse441',
        type: DocumentType.exam,
        dateCreated: DateTime.now(),
      );

      await database.createOrUpdateDocument(doc);

      // Giả lập app khởi động lại và nạp lại từ bộ nhớ thiết bị
      await database.init();

      final reloadedDoc = database.getDocumentById('persistent_doc_1');
      expect(reloadedDoc, isNotNull);
      expect(reloadedDoc!.title, 'Tài liệu Lưu trữ vĩnh viễn');
    });
  });
}
