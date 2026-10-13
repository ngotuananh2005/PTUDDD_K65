import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../models/document_type.dart';
import '../state/document_provider.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/share_document_dialog.dart';
import 'add_edit_document_page.dart';

/// Màn hình Chi tiết Tài liệu học tập
class DocumentDetailPage extends StatelessWidget {
  final String documentId;

  const DocumentDetailPage({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();

    // Tìm trong local SQLite trước
    DocumentModel? found = provider.allDocuments.cast<DocumentModel?>().firstWhere(
      (d) => d!.id == documentId,
      orElse: () => null,
    );
    // Nếu không thấy local → tìm trong tài liệu được chia sẻ từ Supabase
    found ??= provider.sharedDocuments.cast<DocumentModel?>().firstWhere(
      (d) => d!.id == documentId,
      orElse: () => null,
    );
    // Dùng biến document để không thay đổi phần còn lại của file
    final document = found;

    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết tài liệu')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text('Tài liệu đã bị xóa hoặc không tồn tại!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final course = provider.getCourse(document.courseId);
    final courseColor = course?.color ?? theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        actions: [
          IconButton(
            icon: Icon(
              document.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: document.isPinned ? theme.colorScheme.primary : null,
            ),
            tooltip: document.isPinned ? 'Bỏ ghim' : 'Ghim tài liệu',
            onPressed: () => provider.togglePin(document.id),
          ),
          // Chỉ chủ sở hữu mới có quyền Chia sẻ tài liệu
          if (document.isOwner)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Chia sẻ tài liệu',
              onPressed: () => ShareDocumentDialog.show(context, document),
            ),
          // Chỉ hiển thị nút Chỉnh sửa nếu có quyền (Owner hoặc Editor)
          if (document.canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AddEditDocumentPage(documentToEdit: document),
                  ),
                );
              },
            ),
          // Chỉ chủ sở hữu mới có quyền Xóa tài liệu
          if (document.isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa tài liệu',
              onPressed: () async {
                final confirmed = await ConfirmationDialog.show(
                  context: context,
                  title: 'Xác nhận xóa tài liệu',
                  content: 'Bạn có chắc chắn muốn xóa "${document.title}"? Thao tác này không thể hoàn tác.',
                );
                if (confirmed && context.mounted) {
                  await provider.deleteDocument(document.id);
                  if (context.mounted) Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa tài liệu thành công!')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner cảnh báo quyền truy cập nếu là tài liệu được chia sẻ
          if (!document.isOwner)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: document.canEdit
                    ? Colors.blue.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: document.canEdit
                      ? Colors.blue.withValues(alpha: 0.4)
                      : Colors.amber.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    document.canEdit ? Icons.edit_note_rounded : Icons.visibility_rounded,
                    color: document.canEdit ? Colors.blue.shade700 : Colors.amber.shade900,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.canEdit ? 'QUYỀN CHỈNH SỬA (EDITOR)' : 'CHẾ ĐỘ CHỈ XEM (VIEWER)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: document.canEdit ? Colors.blue.shade900 : Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          document.canEdit
                              ? 'Tài liệu từ ${document.ownerEmail ?? "người khác"}. Bạn có thể xem và chỉnh sửa nội dung.'
                              : 'Tài liệu từ ${document.ownerEmail ?? "người khác"}. Bạn chỉ có quyền đọc, không thể chỉnh sửa hoặc xóa.',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Banner môn học & Phân loại
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  courseColor.withValues(alpha: 0.85),
                  courseColor.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(course?.icon ?? Icons.school, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course?.code ?? 'MÔN HỌC',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            course?.name ?? 'Chưa xác định',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(document.type.icon, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            document.type.label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tiêu đề tài liệu
          Text(
            document.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Trạng thái học tập chuyển đổi nhanh
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trạng thái học tập:', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: StudyStatus.values.map((status) {
                      final isSelected = document.status == status;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: !document.canEdit
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Chế độ chỉ xem: Bạn không thể đổi trạng thái tài liệu này!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                : () => provider.updateStatus(document.id, status),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? status.color : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? status.color : theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    status.icon,
                                    size: 16,
                                    color: isSelected ? Colors.white : status.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      status.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata Grid (Thời lượng, Số trang, Mức ưu tiên, Ngày tạo)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetaChip(
                context,
                icon: Icons.timer_outlined,
                title: 'Thời lượng',
                value: '${document.estimatedMinutes} phút',
              ),
              if (document.pageCount > 0)
                _buildMetaChip(
                  context,
                  icon: Icons.find_in_page_outlined,
                  title: 'Số trang',
                  value: '${document.pageCount} trang',
                ),
              _buildMetaChip(
                context,
                icon: Icons.priority_high_rounded,
                title: 'Mức ưu tiên',
                value: document.priority.label,
                valueColor: document.priority.color,
              ),
              if (document.dueDate != null)
                _buildMetaChip(
                  context,
                  icon: Icons.event_rounded,
                  title: 'Hạn chót',
                  value: DateFormat('dd/MM/yyyy').format(document.dueDate!),
                  valueColor: document.dueDate!.isBefore(DateTime.now()) ? Colors.red : null,
                ),
              _buildMetaChip(
                context,
                icon: Icons.calendar_today_outlined,
                title: 'Ngày tạo',
                value: DateFormat('dd/MM/yyyy').format(document.dateCreated),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // File URL hoặc Link
          if (document.fileUrl.isNotEmpty) ...[
            Text('Liên kết / Tệp đính kèm', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.fileUrl,
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Ghi chú và Tóm tắt
          if (document.description.isNotEmpty) ...[
            Text('Nội dung & Tóm tắt', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                document.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Thẻ Tags
          if (document.tags.isNotEmpty) ...[
            Text('Từ khóa / Thẻ tag', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: document.tags.map((tag) {
                return Chip(
                  avatar: const Icon(Icons.tag_rounded, size: 14),
                  label: Text(tag),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChip(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: valueColor ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
