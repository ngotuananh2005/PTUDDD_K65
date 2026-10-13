import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// Provider quản lý trạng thái đăng nhập người dùng và giao tiếp với AuthService
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isGuest = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _init();
  }

  /// Khởi tạo và lắng nghe thay đổi trạng thái xác thực từ Firebase
  void _init() {
    try {
      _user = _authService.currentUser;
      _authSubscription = _authService.authStateChanges.listen((User? user) {
        _user = user;
        if (user != null) {
          _isGuest = false;
        }
        notifyListeners();
      }, onError: (error) {
        debugPrint('Lỗi AuthStateChanges: $error');
      });
    } catch (e) {
      debugPrint('Chưa thể khởi tạo Auth State (Firebase chưa sẵn sàng): $e');
    }
  }

  /// Thông tin người dùng hiện tại
  User? get user => _user;

  /// Đã đăng nhập bằng tài khoản hay chưa
  bool get isAuthenticated => _user != null;

  /// Đang dùng với tư cách Khách
  bool get isGuest => _isGuest;

  /// Cho phép truy cập vào ứng dụng (khi đã đăng nhập hoặc chọn dùng thử dạng Khách)
  bool get canAccessApp => isAuthenticated || _isGuest;

  /// Kích hoạt chế độ dùng thử với vai trò Khách
  void continueAsGuest() {
    _isGuest = true;
    notifyListeners();
  }

  /// Đang trong quá trình xử lý (đăng nhập/đăng xuất)
  bool get isLoading => _isLoading;

  /// Thông điệp lỗi nếu có
  String? get errorMessage => _errorMessage;

  /// Tên hiển thị người dùng hoặc mặc định
  String get displayName => _user?.displayName ?? _user?.email?.split('@').first ?? 'Người dùng';

  /// Email người dùng
  String get email => _user?.email ?? '';

  /// Ảnh đại diện người dùng
  String? get photoUrl => _user?.photoURL;

  /// Thực hiện đăng nhập bằng Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && credential.user != null) {
        _user = credential.user;
        _isLoading = false;
        notifyListeners();

        // Đồng bộ thông tin người dùng lên Supabase profiles
        // Đỏ để người khác có thể tìm thấy khi chia sẻ tài liệu
        final user = credential.user!;
        unawaited(SupabaseService().upsertProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          avatarUrl: user.photoURL,
        ));

        return true;
      } else {
        // Người dùng đã hủy quá trình đăng nhập
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Thực hiện đăng xuất
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _isGuest = false;
    } catch (e) {
      _errorMessage = 'Đăng xuất thất bại: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa thông báo lỗi
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
