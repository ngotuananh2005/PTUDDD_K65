import 'dart:convert';
import '../models/course_model.dart';
import '../models/document_model.dart';

/// Dịch vụ Sao lưu và Xuất dữ liệu (Local-first Backup Strategy theo chuẩn Cashew)
class BackupExportService {
  /// Xuất toàn bộ dữ liệu ra định dạng JSON
  static String exportDatabaseToJson({
    required List<CourseModel> courses,
    required List<DocumentModel> documents,
  }) {
    final Map<String, dynamic> data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'StudyDocumentManager_TH1',
      'version': '1.0.0',
      'courses': courses.map((c) => c.toMap()).toList(),
      'documents': documents.map((d) => d.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Xuất danh sách tài liệu ra định dạng CSV (tương thích Excel / Google Sheets)
  static String exportDocumentsToCsv({
    required List<DocumentModel> documents,
    required List<CourseModel> courses,
  }) {
    final StringBuffer csv = StringBuffer();
    // Tiêu đề cột
    csv.writeln(
      'Mã ID,Tiêu đề,Môn học,Mã môn,Loại tài liệu,Trạng thái,Mức ưu tiên,Số trang,Thời lượng (phút),Yêu thích,Hạn chót,Ngày tạo',
    );

    final Map<String, CourseModel> courseMap = {
      for (var c in courses) c.courseId: c,
    };

    for (var doc in documents) {
      final course = courseMap[doc.courseId];
      final courseName = course?.name ?? 'Chưa xác định';
      final courseCode = course?.code ?? '';

      final String cleanTitle = '"${doc.title.replaceAll('"', '""')}"';
      final String cleanCourseName = '"${courseName.replaceAll('"', '""')}"';

      csv.writeln(
        '${doc.id},$cleanTitle,$cleanCourseName,$courseCode,${doc.type.label},${doc.status.label},${doc.priority.label},${doc.pageCount},${doc.estimatedMinutes},${doc.isPinned ? "Có" : "Không"},${doc.dueDate?.toIso8601String() ?? ""},${doc.dateCreated.toIso8601String()}',
      );
    }

    return csv.toString();
  }
}
