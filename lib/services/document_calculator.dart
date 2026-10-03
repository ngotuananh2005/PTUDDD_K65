import '../models/course_model.dart';
import '../models/document_model.dart';
import '../models/document_type.dart';

/// Dữ liệu thống kê tổng hợp về tài liệu học tập
class StudyOverviewStatistics {
  final int totalDocuments;
  final int completedDocuments;
  final int inProgressDocuments;
  final int pendingDocuments;
  final double overallCompletionRate; // 0.0 đến 1.0
  final int totalEstimatedHours;
  final int completedEstimatedHours;
  final int urgentDueDocumentsCount; // Tài liệu/bài tập sắp đến hạn trong vòng 7 ngày

  const StudyOverviewStatistics({
    required this.totalDocuments,
    required this.completedDocuments,
    required this.inProgressDocuments,
    required this.pendingDocuments,
    required this.overallCompletionRate,
    required this.totalEstimatedHours,
    required this.completedEstimatedHours,
    required this.urgentDueDocumentsCount,
  });
}

/// Dữ liệu thống kê theo từng môn học (Tương đương thống kê Ngân sách theo Danh mục trong Cashew)
class CourseStudyProgress {
  final CourseModel course;
  final int totalCount;
  final int completedCount;
  final double progressPercent; // 0.0 -> 100.0%
  final int lectureCount;
  final int exerciseCount;
  final int referenceCount;
  final int examCount;

  const CourseStudyProgress({
    required this.course,
    required this.totalCount,
    required this.completedCount,
    required this.progressPercent,
    required this.lectureCount,
    required this.exerciseCount,
    required this.referenceCount,
    required this.examCount,
  });
}

/// Bộ tính toán nghiệp vụ tài liệu học tập (Business & Calculation Service)
/// Tương tự các bộ tính toán tài chính BudgetPeriod, SavingsPlannerCalculator trong Cashew
class DocumentCalculator {
  /// Tính toán thống kê tổng quan toàn bộ hệ thống
  static StudyOverviewStatistics calculateOverview(List<DocumentModel> documents) {
    if (documents.isEmpty) {
      return const StudyOverviewStatistics(
        totalDocuments: 0,
        completedDocuments: 0,
        inProgressDocuments: 0,
        pendingDocuments: 0,
        overallCompletionRate: 0.0,
        totalEstimatedHours: 0,
        completedEstimatedHours: 0,
        urgentDueDocumentsCount: 0,
      );
    }

    int completed = 0;
    int inProgress = 0;
    int pending = 0;
    int totalMinutes = 0;
    int completedMinutes = 0;
    int urgentDue = 0;

    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    for (var doc in documents) {
      totalMinutes += doc.estimatedMinutes;

      switch (doc.status) {
        case StudyStatus.completed:
          completed++;
          completedMinutes += doc.estimatedMinutes;
          break;
        case StudyStatus.inProgress:
          inProgress++;
          break;
        case StudyStatus.pending:
          pending++;
          break;
      }

      // Kiểm tra hạn chót nếu chưa hoàn thành
      if (doc.status != StudyStatus.completed && doc.dueDate != null) {
        if (doc.dueDate!.isAfter(now) && doc.dueDate!.isBefore(sevenDaysFromNow)) {
          urgentDue++;
        }
      }
    }

    final double completionRate = documents.isNotEmpty ? (completed / documents.length) : 0.0;

    return StudyOverviewStatistics(
      totalDocuments: documents.length,
      completedDocuments: completed,
      inProgressDocuments: inProgress,
      pendingDocuments: pending,
      overallCompletionRate: completionRate,
      totalEstimatedHours: (totalMinutes / 60).round(),
      completedEstimatedHours: (completedMinutes / 60).round(),
      urgentDueDocumentsCount: urgentDue,
    );
  }

  /// Tính toán tiến độ và phân bố tài liệu theo từng môn học
  static List<CourseStudyProgress> calculateProgressByCourses({
    required List<CourseModel> courses,
    required List<DocumentModel> documents,
  }) {
    final List<CourseStudyProgress> results = [];

    for (var course in courses) {
      final courseDocs = documents.where((d) => d.courseId == course.courseId).toList();
      final total = courseDocs.length;
      final completed = courseDocs.where((d) => d.status == StudyStatus.completed).length;

      final double progress = total > 0 ? (completed / total) * 100.0 : 0.0;

      final lectures = courseDocs.where((d) => d.type == DocumentType.lecture).length;
      final exercises = courseDocs.where((d) => d.type == DocumentType.exercise).length;
      final references = courseDocs.where((d) => d.type == DocumentType.reference).length;
      final exams = courseDocs.where((d) => d.type == DocumentType.exam).length;

      results.add(CourseStudyProgress(
        course: course,
        totalCount: total,
        completedCount: completed,
        progressPercent: progress,
        lectureCount: lectures,
        exerciseCount: exercises,
        referenceCount: references,
        examCount: exams,
      ));
    }

    return results;
  }

  /// Phân bố số lượng tài liệu theo Loại tài liệu (DocumentType)
  static Map<DocumentType, int> getDistributionByType(List<DocumentModel> documents) {
    final Map<DocumentType, int> map = {
      DocumentType.lecture: 0,
      DocumentType.exercise: 0,
      DocumentType.reference: 0,
      DocumentType.exam: 0,
    };

    for (var doc in documents) {
      map[doc.type] = (map[doc.type] ?? 0) + 1;
    }

    return map;
  }
}
