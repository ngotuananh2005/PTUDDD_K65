import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service xử lý xác thực người dùng qua Firebase Auth và Google Sign-In
class AuthService {
  /// Getter an toàn cho FirebaseAuth, tránh crash khi chưa khởi tạo (ví dụ: môi trường Unit Test)
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth chưa khởi tạo: $e');
      return null;
    }
  }

  /// Lấy thông tin người dùng đang đăng nhập hiện tại
  User? get currentUser => _auth?.currentUser;

  /// Stream theo dõi sự thay đổi trạng thái xác thực
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// Đăng nhập bằng tài khoản Google
  /// Hỗ trợ mượt mà cả Web (Popup) và Thiết bị di động (Android / iOS)
  Future<UserCredential?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase chưa được khởi tạo. Vui lòng kiểm tra kết nối và cấu hình Firebase.');
    }

    try {
      if (kIsWeb) {
        // Trên Web: Firebase Auth Popup là phương thức chuẩn, trực quan nhất
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await auth.signInWithPopup(googleProvider);
      } else {
        // Web Client ID lấy từ file android/app/google-services.json (client_type: 3)
        const String serverClientId =
            '293116833744-augg57j4t4c2l6ohqas4loc4pl62jue4.apps.googleusercontent.com';

        // Trên thiết bị di động (Android / iOS): Cần cung cấp serverClientId (Web Client ID của Firebase)
        await GoogleSignIn.instance.initialize(
          serverClientId: serverClientId,
        );

        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate(
          scopeHint: const ['email', 'profile'],
        );

        final String? idToken = googleUser.authentication.idToken;
        final GoogleSignInClientAuthorization? authorization =
            await googleUser.authorizationClient.authorizationForScopes(
          const ['email', 'profile'],
        );
        final String? accessToken = authorization?.accessToken;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );

        return await auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException trong signInWithGoogle: [${e.code}] ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('Lỗi đăng nhập Google: $errorStr');
      if (errorStr.toLowerCase().contains('cancel') ||
          errorStr.toLowerCase().contains('abort') ||
          errorStr.toLowerCase().contains('closed')) {
        // Người dùng tự đóng hoặc hủy hộp thoại đăng nhập
        return null;
      }
      throw Exception('Không thể đăng nhập Google: $errorStr');
    }
  }

  /// Đăng xuất khỏi Firebase và Google Sign-In
  Future<void> signOut() async {
    final auth = _auth;
    try {
      await Future.wait([
        if (auth != null) auth.signOut(),
        if (!kIsWeb) GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      debugPrint('Lỗi khi đăng xuất: $e');
      if (auth != null) {
        await auth.signOut();
      }
    }
  }

  /// Chuyển đổi mã lỗi Firebase sang thông điệp tiếng Việt dễ hiểu
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Tài khoản đã tồn tại với phương thức đăng nhập khác.';
      case 'invalid-credential':
        return 'Thông tin xác thực Google không hợp lệ hoặc đã hết hạn.';
      case 'operation-not-allowed':
        return 'Chức năng Google Sign-In chưa được bật trong Firebase Console (Authentication -> Sign-in method).';
      case 'user-disabled':
        return 'Tài khoản người dùng này đã bị khóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản người dùng tương ứng.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền internet.';
      case 'popup-closed-by-user':
        return 'Cửa sổ đăng nhập đã bị đóng trước khi hoàn tất.';
      case 'cancelled':
        return 'Thao tác đăng nhập Google đã bị hủy.';
      default:
        return e.message ?? 'Đăng nhập thất bại (mã: ${e.code})';
    }
  }
}
