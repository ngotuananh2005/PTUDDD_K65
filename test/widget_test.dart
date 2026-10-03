import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectsth1/main.dart';
import 'package:projectsth1/widgets/progress_gauge.dart';

void main() {
  group('TẦNG GIAO DIỆN (Presentation Layer / Widget Tests)', () {
    testWidgets('1. Kiểm thử render Ứng dụng Cashew StudyDocs', (WidgetTester tester) async {
      await tester.pumpWidget(const StudyDocumentApp());
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề trên AppBar
      expect(find.text('Cashew StudyDocs'), findsOneWidget);
      expect(find.text('Quản lý Tài liệu Học tập'), findsOneWidget);

      // Kiểm tra thanh điều hướng dưới đáy (Bottom Navigation Bar)
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Tài liệu'), findsOneWidget);
      expect(find.text('Thống kê'), findsOneWidget);
    });

    testWidgets('2. Kiểm thử chuyển đổi tab sang Kho Tài liệu', (WidgetTester tester) async {
      await tester.pumpWidget(const StudyDocumentApp());
      await tester.pumpAndSettle();

      // Nhấn vào tab "Tài liệu"
      await tester.tap(find.text('Tài liệu'));
      await tester.pumpAndSettle();

      // Kiểm tra đã sang màn hình Kho tài liệu
      expect(find.text('Kho Tài liệu Học tập'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Thanh tìm kiếm
      expect(find.text('Tất cả môn'), findsOneWidget);
    });

    testWidgets('3. Kiểm thử Widget Vòng tiến độ (ProgressGaugeWidget)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressGaugeWidget(
              percentage: 0.75,
              title: 'Tiến độ kiểm thử',
              subtitle: 'Đã hoàn thành 3/4',
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Tiến độ kiểm thử'), findsOneWidget);
      expect(find.text('Đã hoàn thành 3/4'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
