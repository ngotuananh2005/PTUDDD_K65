import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/app_database.dart';
import 'pages/main_navigation_shell.dart';
import 'state/document_provider.dart';
import 'state/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudyAppDatabase().init();
  runApp(const StudyDocumentApp());
}

class StudyDocumentApp extends StatelessWidget {
  const StudyDocumentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => DocumentProvider(database: StudyAppDatabase()),
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
            home: const MainNavigationShell(),
          );
        },
      ),
    );
  }
}
