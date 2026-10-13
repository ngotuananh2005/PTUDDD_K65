import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'database/app_database.dart';
import 'pages/login_page.dart';
import 'pages/main_navigation_shell.dart';
import 'services/supabase_service.dart';
import 'state/auth_provider.dart';
import 'state/document_provider.dart';
import 'state/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo cơ sở dữ liệu nội bộ
  await StudyAppDatabase().init();

  // Khởi tạo Firebase với cấu hình đa nền tảng
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Cảnh báo khởi tạo Firebase: $e');
  }

  // Khởi tạo kết nối Supabase Cloud
  await SupabaseService.initialize();

  runApp(const StudyDocumentApp());
}

class StudyDocumentApp extends StatelessWidget {
  const StudyDocumentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // DocumentProvider lắng nghe AuthProvider để load tài liệu được chia sẻ
        ChangeNotifierProxyProvider<AuthProvider, DocumentProvider>(
          create: (_) => DocumentProvider(database: StudyAppDatabase()),
          update: (ctx, auth, docProvider) {
            // Khi user đăng nhập/đăng xuất → load hoặc xóa sharedDocuments
            final uid = auth.user?.uid;
            docProvider?.onUserChanged(uid);
            return docProvider!;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Cashew StudyDocs',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF1E88E5), // Cashew primary blue
              brightness: Brightness.light,
              cardTheme: const CardThemeData(
                elevation: 0,
                margin: EdgeInsets.zero,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF1E88E5),
              brightness: Brightness.dark,
              cardTheme: const CardThemeData(
                elevation: 0,
                margin: EdgeInsets.zero,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
              ),
            ),
            // Khi mở web/app: Hiển thị LoginPage đầu tiên nếu chưa đăng nhập
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.canAccessApp) {
                  return const MainNavigationShell();
                }
                return const LoginPage();
              },
            ),
          );
        },
      ),
    );
  }
}
