import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course_model.dart';
import '../models/document_model.dart';
import '../models/document_type.dart';

/// Card hiển thị thông tin 1 tài liệu học tập
class DocumentCardWidget extends StatelessWidget {
  final DocumentModel document;
  final CourseModel? course;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final ValueChanged<StudyStatus> onStatusChange;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DocumentCardWidget({
    super.key,
    required this.document,
    this.course,
    required this.onTap,
    required this.onTogglePin,
    required this.onStatusChange,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseColor = course?.color ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: document.isPinned
              ? courseColor.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: document.isPinned ? 1.5 : 1.0,
        ),
      ),
      color: document.isPinned
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng 1: Course badge, Type badge, Pin button, Popup menu
              Row(
                children: [
                  // Môn học Badge
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: courseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: courseColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(course?.icon ?? Icons.school, size: 14, color: courseColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              course?.code ?? 'Môn học',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: courseColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Phân loại tài liệu Badge
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: document.type.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(document.type.icon, size: 13, color: document.type.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              document.type.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: document.type.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Nút ghim yêu thích
                  IconButton(
                    icon: Icon(
                      document.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      color: document.isPinned
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: document.isPinned ? 'Bỏ ghim' : 'Ghim tài liệu',
                    onPressed: onTogglePin,
                  ),
                  // Menu tùy chọn (Sửa / Xóa)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: theme.colorScheme.onSurfaceVariant, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa tài liệu', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hàng 2: Tiêu đề tài liệu
              Text(
                document.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: document.status == StudyStatus.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (document.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  document.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Hàng 3: Metadata (Thời gian đọc, Deadline, Trạng thái học)
              Row(
                children: [
                  // Thời lượng đọc / số trang
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${document.estimatedMinutes}p',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (document.pageCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${document.pageCount} trang',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Hạn chót nếu có
                  if (document.dueDate != null) ...[
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_outlined,
                            size: 14,
                            color: document.dueDate!.isBefore(DateTime.now())
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM').format(document.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: document.dueDate!.isBefore(DateTime.now())
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Quick toggle status chip
                  PopupMenuButton<StudyStatus>(
                    initialValue: document.status,
                    tooltip: 'Đổi trạng thái học tập',
                    onSelected: onStatusChange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: document.status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(document.status.icon,
                              size: 14, color: document.status.color),
                          const SizedBox(width: 4),
                          Text(
                            document.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: document.status.color,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down,
                              size: 14, color: document.status.color),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => StudyStatus.values.map((status) {
                      return PopupMenuItem<StudyStatus>(
                        value: status,
                        child: Row(
                          children: [
                            Icon(status.icon, size: 18, color: status.color),
                            const SizedBox(width: 8),
                            Text(status.label),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
