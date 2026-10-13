import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectsth1/main.dart';
import 'package:projectsth1/widgets/google_sign_in_button.dart';
import 'package:projectsth1/widgets/progress_gauge.dart';

void main() {
  group('TẦNG GIAO DIỆN (Presentation Layer / Widget Tests)', () {
    testWidgets('1. Kiểm thử render Trang Đăng nhập (LoginPage) đầu tiên khi mở ứng dụng', (WidgetTester tester) async {
      await tester.pumpWidget(const StudyDocumentApp());
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và thương hiệu trên Trang Đăng nhập
      expect(find.text('Cashew StudyDocs'), findsOneWidget);
      expect(find.text('Quản lý Tài liệu Học tập & Tiến độ Sinh viên'), findsOneWidget);

      // Kiểm tra sự xuất hiện của nút Đăng nhập Google và nút Dùng thử dạng Khách
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Đăng nhập bằng tài khoản Google'), findsOneWidget);
      expect(find.text('Tiếp tục với tư cách Khách (Dùng thử)'), findsOneWidget);
    });

    testWidgets('2. Kiểm thử đăng nhập dạng Khách và điều hướng sang Kho Tài liệu', (WidgetTester tester) async {
      await tester.pumpWidget(const StudyDocumentApp());
      await tester.pumpAndSettle();

      // Bấm vào "Tiếp tục với tư cách Khách (Dùng thử)" để vào ứng dụng
      final guestButton = find.text('Tiếp tục với tư cách Khách (Dùng thử)');
      await tester.ensureVisible(guestButton);
      await tester.pumpAndSettle();
      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      // Kiểm tra thanh điều hướng dưới đáy đã xuất hiện
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Tài liệu'), findsOneWidget);
      expect(find.text('Thống kê'), findsOneWidget);

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
