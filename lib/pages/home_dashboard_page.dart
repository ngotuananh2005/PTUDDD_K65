import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/document_provider.dart';
import '../state/theme_provider.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/course_chip.dart';
import '../widgets/document_card.dart';
import '../widgets/progress_gauge.dart';
import '../widgets/user_profile_dialog.dart';
import 'add_edit_document_page.dart';
import 'document_detail_page.dart';

/// Màn hình Trang chủ (Dashboard Tổng quan)
class HomeDashboardPage extends StatelessWidget {
  final VoidCallback onNavigateToDocuments;

  const HomeDashboardPage({super.key, required this.onNavigateToDocuments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    final stats = provider.overviewStats;
    final pinnedDocs = provider.pinnedDocuments;
    final allDocs = provider.allDocuments;
    final courses = provider.courses;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cashew StudyDocs',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Quản lý Tài liệu Học tập',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle (Dark / Light)
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: themeProvider.isDarkMode ? 'Chuyển sang chế độ Sáng' : 'Chuyển sang chế độ Tối',
            onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
          ),
          // User Profile / Google Sign-In Action
          IconButton(
            tooltip: auth.isAuthenticated ? 'Tài khoản: ${auth.displayName}' : 'Đăng nhập Google',
            icon: auth.isAuthenticated
                ? CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                    child: auth.photoUrl == null
                        ? Text(
                            auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  )
                : const Icon(Icons.account_circle_outlined),
            onPressed: () => UserProfileDialog.show(context),
          ),
          // Reset Database popup
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Khôi phục dữ liệu mẫu',
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context: context,
                title: 'Khôi phục dữ liệu mặc định',
                content: 'Hệ thống sẽ tải lại danh sách môn học và tài liệu mẫu ban đầu. Tiếp tục?',
                confirmText: 'Khôi phục',
                confirmColor: theme.colorScheme.primary,
              );
              if (confirmed) {
                await provider.resetData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã khôi phục dữ liệu mẫu ban đầu!')),
                  );
                }
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const AddEditDocumentPage(),
            ),
          );
        },
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // Banner Đăng nhập Google / Trạng thái tài khoản
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: auth.isAuthenticated
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.green.withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                                child: auth.photoUrl == null
                                    ? Text(
                                        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Xin chào, ${auth.displayName}!',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'Đã kết nối Firebase Google Cloud',
                                      style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => UserProfileDialog.show(context),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                child: const Text('Hồ sơ'),
                              ),
                            ],
                          ),
                        )
                      : Material(
                          color: theme.colorScheme.primaryContainer.withAlpha(45),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => UserProfileDialog.show(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(25),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.login_rounded, color: Color(0xFF4285F4), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Đăng nhập với Google',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Đồng bộ tài liệu và bảo vệ dữ liệu học tập',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),

                // 1. Thẻ tiến độ tổng quan (Gauge)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ProgressGaugeWidget(
                    percentage: stats.overallCompletionRate,
                    title: 'Tiến độ học tập kỳ này',
                    subtitle: 'Hoàn thành ${stats.completedDocuments} trên tổng số ${stats.totalDocuments} tài liệu',
                  ),
                ),

                // 2. Danh mục môn học (Course Chips Carousel)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Môn học (${courses.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: onNavigateToDocuments,
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final c = courses[index];
                      final count = allDocs.where((d) => d.courseId == c.courseId).length;
                      return CourseChipWidget(
                        course: c,
                        isSelected: false,
                        label: '${c.code} (${c.name})',
                        count: count,
                        onTap: () {
                          provider.setSelectedCourse(c.courseId);
                          onNavigateToDocuments();
                        },
                      );
                    },
                  ),
                ),

                // 3. Tài liệu được ghim / Ưu tiên (Pinned Documents)
                if (pinnedDocs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Row(
                      children: [
                        Icon(Icons.push_pin_rounded, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tài liệu quan trọng / Đã ghim (${pinnedDocs.length})',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...pinnedDocs.map((doc) {
                    final course = provider.getCourse(doc.courseId);
                    return DocumentCardWidget(
                      document: doc,
                      course: course,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => DocumentDetailPage(documentId: doc.id),
                          ),
                        );
                      },
                      onTogglePin: () => provider.togglePin(doc.id),
                      onStatusChange: (status) => provider.updateStatus(doc.id, status),
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AddEditDocumentPage(documentToEdit: doc),
                          ),
                        );
                      },
                      onDelete: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context: context,
                          title: 'Xóa tài liệu',
                          content: 'Bạn có chắc chắn muốn xóa "${doc.title}"?',
                        );
                        if (confirmed) {
                          await provider.deleteDocument(doc.id);
                        }
                      },
                    );
                  }),
                ],

                // 4. Tài liệu học tập gần đây (Recent Documents)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tất cả tài liệu gần đây',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: onNavigateToDocuments,
                        child: const Text('Mở kho tài liệu'),
                      ),
                    ],
                  ),
                ),
                ...allDocs.take(6).map((doc) {
                  final course = provider.getCourse(doc.courseId);
                  return DocumentCardWidget(
                    document: doc,
                    course: course,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => DocumentDetailPage(documentId: doc.id),
                        ),
                      );
                    },
                    onTogglePin: () => provider.togglePin(doc.id),
                    onStatusChange: (status) => provider.updateStatus(doc.id, status),
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => AddEditDocumentPage(documentToEdit: doc),
                        ),
                      );
                    },
                    onDelete: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context: context,
                        title: 'Xóa tài liệu',
                        content: 'Bạn có chắc chắn muốn xóa "${doc.title}"?',
                      );
                      if (confirmed) {
                        await provider.deleteDocument(doc.id);
                      }
                    },
                  );
                }),
              ],
            ),
    );
  }
}
