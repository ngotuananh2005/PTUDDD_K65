import 'package:flutter_test/flutter_test.dart';
import 'package:projectsth1/services/auth_service.dart';
import 'package:projectsth1/state/auth_provider.dart';

void main() {
  group('TẦNG XÁC THỰC (Authentication & Firebase Tests)', () {
    test('1. AuthProvider khởi tạo an toàn ở trạng thái chưa đăng nhập', () {
      final provider = AuthProvider(authService: AuthService());

      expect(provider.isAuthenticated, isFalse);
      expect(provider.user, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.displayName, equals('Người dùng'));
      expect(provider.email, isEmpty);
      expect(provider.photoUrl, isNull);
    });

    test('2. AuthProvider quản lý thông báo lỗi và clearError', () {
      final provider = AuthProvider(authService: AuthService());

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });

    test('3. AuthService xử lý ngoại lệ khi chưa kết nối Firebase Console', () async {
      final service = AuthService();

      // Kiểm tra an toàn khi Firebase chưa init ở môi trường local unit test
      expect(service.currentUser, isNull);
      expect(service.authStateChanges, emitsDone);
    });
  });
}
