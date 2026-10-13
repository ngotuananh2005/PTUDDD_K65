// File generated to provide Firebase options for each platform.
// Tham khảo: https://firebase.flutter.dev/docs/overview#initialization
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình mặc định cho Firebase theo từng nền tảng (Android, Web, iOS, Windows).
///
/// HƯỚNG DẪN CẤU HÌNH THỰC TẾ:
/// 1. Vào https://console.firebase.google.com và tạo dự án mới.
/// 2. Bật "Google Sign-In" trong mục Build -> Authentication -> Sign-in method.
/// 3. Chạy lệnh: `flutterfire configure` (nếu đã cài FlutterFire CLI)
///    HOẶC điền các thông tin (apiKey, appId, projectId, messagingSenderId) từ Firebase Console vào dưới đây.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // Cấu hình cho nền tảng Web
  // Thay thế bằng Client ID và API Key từ Firebase Console -> Project Settings -> General -> Web Apps
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5GXX5auZzctZ8OzuizoiIJ564yW0Zu1A',
    appId: '1:293116833744:web:211455f498d66fa73253d5',
    messagingSenderId: '293116833744',
    projectId: 'projectth1s',
    authDomain: 'projectth1s.firebaseapp.com',
    storageBucket: 'projectth1s.firebasestorage.app',
  );

  // Cấu hình cho nền tảng Android
  // Lấy từ file google-services.json tải về từ Firebase Console -> Android Apps
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderApiKeyForAndroid12345',
    appId: '1:1234567890:android:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'cashew-studydocs-demo',
    storageBucket: 'cashew-studydocs-demo.appspot.com',
  );

  // Cấu hình cho nền tảng iOS
  // Lấy từ GoogleService-Info.plist tải về từ Firebase Console -> iOS Apps
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderApiKeyForIOS123456789',
    appId: '1:1234567890:ios:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'cashew-studydocs-demo',
    storageBucket: 'cashew-studydocs-demo.appspot.com',
    iosBundleId: 'com.example.projectsth1',
  );
}
