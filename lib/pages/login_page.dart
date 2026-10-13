import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/theme_provider.dart';
import '../widgets/google_sign_in_button.dart';

/// Màn hình Đăng nhập chính khi mở ứng dụng
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Nút chuyển đổi giao diện Sáng / Tối
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: themeProvider.isDarkMode
                ? 'Chuyển sang chế độ Sáng'
                : 'Chuyển sang chế độ Tối',
            onPressed: () =>
                themeProvider.toggleTheme(!themeProvider.isDarkMode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 36,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo & Icon ứng dụng
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(40),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 52,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tiêu đề ứng dụng
                      Text(
                        'Cashew StudyDocs',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quản lý Tài liệu Học tập & Tiến độ Sinh viên',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Danh sách tính năng nổi bật
                      _buildFeatureTile(
                        context,
                        icon: Icons.cloud_done_rounded,
                        color: Colors.blue,
                        title: 'Đồng bộ Google Cloud',
                        subtitle: 'Lưu trữ tài liệu và ghi chú học tập an toàn',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        context,
                        icon: Icons.donut_large_rounded,
                        color: Colors.teal,
                        title: 'Theo dõi tiến độ học kỳ',
                        subtitle: 'Thống kê trực quan số tài liệu đã hoàn thành',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureTile(
                        context,
                        icon: Icons.folder_special_rounded,
                        color: Colors.orange,
                        title: 'Phân loại môn học thông minh',
                        subtitle: 'Gắn thẻ, lọc và tìm kiếm theo kiến trúc Cashew',
                      ),
                      const SizedBox(height: 28),

                      // Thông báo lỗi nếu đăng nhập thất bại
                      if (auth.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => auth.clearError(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Nút Đăng nhập bằng Google
                      SizedBox(
                        width: double.infinity,
                        child: GoogleSignInButton(
                          isLoading: auth.isLoading,
                          text: 'Đăng nhập bằng tài khoản Google',
                          onPressed: () async {
                            final success = await auth.signInWithGoogle();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Chào mừng ${auth.displayName} đã đăng nhập thành công!',
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nút Tiếp tục dùng thử với vai trò Khách
                      TextButton.icon(
                        onPressed: auth.isLoading
                            ? null
                            : () {
                                auth.continueAsGuest();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bạn đang sử dụng ứng dụng với chế độ Khách (Offline)',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.person_outline_rounded, size: 18),
                        label: const Text(
                          'Tiếp tục với tư cách Khách (Dùng thử)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
