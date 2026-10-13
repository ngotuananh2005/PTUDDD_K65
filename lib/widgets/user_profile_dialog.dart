import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import 'google_sign_in_button.dart';

/// Hộp thoại xem thông tin tài khoản hoặc thực hiện đăng nhập Google
class UserProfileDialog extends StatelessWidget {
  const UserProfileDialog({super.key});

  /// Hàm tiện ích mở hộp thoại
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const UserProfileDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tiêu đề
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      auth.isAuthenticated ? Icons.verified_user_rounded : Icons.account_circle_rounded,
                      color: auth.isAuthenticated ? Colors.green : theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      auth.isAuthenticated ? 'Tài khoản của bạn' : 'Đăng nhập ứng dụng',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Đóng',
                ),
              ],
            ),
            const Divider(height: 24),

            if (auth.isAuthenticated && user != null) ...[
              // Giao diện khi ĐÃ ĐĂNG NHẬP
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? Text(
                        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                auth.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                auth.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Đã kết nối Firebase Google Auth',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          await auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã đăng xuất thành công')),
                            );
                          }
                        },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              // Giao diện khi CHƯA ĐĂNG NHẬP
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_sync_rounded, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Đồng bộ tài liệu học tập',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đăng nhập bằng tài khoản Google để lưu trữ dữ liệu môn học, tài liệu và tiến độ học tập an toàn trên Firebase Cloud.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (auth.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              GoogleSignInButton(
                isLoading: auth.isLoading,
                onPressed: () async {
                  final success = await auth.signInWithGoogle();
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chào mừng ${auth.displayName} đã đăng nhập thành công!'),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
