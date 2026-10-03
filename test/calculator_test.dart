import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectsth1/models/course_model.dart';
import 'package:projectsth1/models/document_model.dart';
import 'package:projectsth1/models/document_type.dart';
import 'package:projectsth1/services/document_calculator.dart';

void main() {
  group('TẦNG NGHIỆP VỤ & TÍNH TOÁN (Business & Domain Logic Tests)', () {
    final now = DateTime.now();

    final testCourses = [
      CourseModel(
        courseId: 'c1',
        name: 'Lập trình Di động',
        code: 'CSE441',
        color: Colors.blue,
        icon: Icons.phone_android,
        dateCreated: now,
      ),
      CourseModel(
        courseId: 'c2',
        name: 'Cấu trúc dữ liệu',
        code: 'CSE381',
        color: Colors.purple,
        icon: Icons.account_tree,
        dateCreated: now,
      ),
    ];

    final testDocs = [
      DocumentModel(
        id: 'd1',
        title: 'Tài liệu 1',
        courseId: 'c1',
        type: DocumentType.lecture,
        status: StudyStatus.completed,
        estimatedMinutes: 60,
        dateCreated: now,
      ),
      DocumentModel(
        id: 'd2',
        title: 'Tài liệu 2',
        courseId: 'c1',
        type: DocumentType.exercise,
        status: StudyStatus.inProgress,
        estimatedMinutes: 120,
        dueDate: now.add(const Duration(days: 2)), // Sắp đến hạn
        dateCreated: now,
      ),
      DocumentModel(
        id: 'd3',
        title: 'Tài liệu 3',
        courseId: 'c2',
        type: DocumentType.reference,
        status: StudyStatus.pending,
        estimatedMinutes: 30,
        dateCreated: now,
      ),
      DocumentModel(
        id: 'd4',
        title: 'Tài liệu 4',
        courseId: 'c2',
        type: DocumentType.exam,
        status: StudyStatus.completed,
        estimatedMinutes: 90,
        dateCreated: now,
      ),
    ];

    test('1. Tính toán thống kê tổng quan (Overall Overview Statistics)', () {
      final stats = DocumentCalculator.calculateOverview(testDocs);

      expect(stats.totalDocuments, 4);
      expect(stats.completedDocuments, 2);
      expect(stats.inProgressDocuments, 1);
      expect(stats.pendingDocuments, 1);
      expect(stats.overallCompletionRate, 0.5); // 2/4 = 50%
      expect(stats.totalEstimatedHours, 5); // (60 + 120 + 30 + 90) / 60 = 5 giờ
      expect(stats.completedEstimatedHours, 3); // (60 + 90) / 60 = 2.5 làm tròn 3 giờ
      expect(stats.urgentDueDocumentsCount, 1); // d2 có hạn chót trong vòng 7 ngày
    });

    test('2. Tính toán tiến độ theo từng môn học (Course Progress)', () {
      final progressList = DocumentCalculator.calculateProgressByCourses(
        courses: testCourses,
        documents: testDocs,
      );

      expect(progressList.length, 2);

      // Môn C1 (CSE441): Có 2 tài liệu (d1 completed, d2 inProgress) => 50%
      final c1Progress = progressList.firstWhere((p) => p.course.courseId == 'c1');
      expect(c1Progress.totalCount, 2);
      expect(c1Progress.completedCount, 1);
      expect(c1Progress.progressPercent, 50.0);
      expect(c1Progress.lectureCount, 1);
      expect(c1Progress.exerciseCount, 1);

      // Môn C2 (CSE381): Có 2 tài liệu (d3 pending, d4 completed) => 50%
      final c2Progress = progressList.firstWhere((p) => p.course.courseId == 'c2');
      expect(c2Progress.totalCount, 2);
      expect(c2Progress.completedCount, 1);
      expect(c2Progress.progressPercent, 50.0);
      expect(c2Progress.referenceCount, 1);
      expect(c2Progress.examCount, 1);
    });

    test('3. Phân bố theo Phân loại tài liệu (Type Distribution)', () {
      final distribution = DocumentCalculator.getDistributionByType(testDocs);

      expect(distribution[DocumentType.lecture], 1);
      expect(distribution[DocumentType.exercise], 1);
      expect(distribution[DocumentType.reference], 1);
      expect(distribution[DocumentType.exam], 1);
    });

    test('4. Xử lý danh sách rỗng an toàn (Edge Case: Empty List)', () {
      final stats = DocumentCalculator.calculateOverview([]);
      expect(stats.totalDocuments, 0);
      expect(stats.overallCompletionRate, 0.0);
      expect(stats.totalEstimatedHours, 0);
    });
  });
}
