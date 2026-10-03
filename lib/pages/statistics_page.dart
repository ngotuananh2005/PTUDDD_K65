import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/document_type.dart';
import '../services/backup_export_service.dart';
import '../state/document_provider.dart';
import '../widgets/progress_gauge.dart';

/// Màn hình Thống kê Tiến độ & Sao lưu Dữ liệu (Local-first Analytics & Backup)
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  void _showExportDialog(BuildContext context, {required String title, required String content, required String fileType}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.file_download_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dữ liệu đã được trích xuất sẵn sàng dưới dạng $fileType:'),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép vào Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép nội dung $fileType vào bộ nhớ tạm!')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();

    final stats = provider.overviewStats;
    final courseProgressList = provider.courseProgressList;
    final typeDistribution = provider.typeDistribution;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê & Báo cáo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Vòng tiến độ tổng quan (Gauge)
          ProgressGaugeWidget(
            percentage: stats.overallCompletionRate,
            title: 'Tiến độ học tập tổng thể',
            subtitle: 'Đã hoàn thành ${stats.completedDocuments}/${stats.totalDocuments} tài liệu',
          ),
          const SizedBox(height: 16),

          // 2. Thống kê theo Thẻ số (Grid Quick Stats)
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Đang học',
                  value: '${stats.inProgressDocuments}',
                  icon: Icons.timelapse_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Chưa học',
                  value: '${stats.pendingDocuments}',
                  icon: Icons.schedule_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Sắp đến hạn',
                  value: '${stats.urgentDueDocumentsCount}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Tiến độ theo từng môn học (Course Progress Bars)
          Text(
            'Tiến độ theo Môn học',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...courseProgressList.map((cp) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cp.course.color.withValues(alpha: 0.15),
                          child: Icon(cp.course.icon, size: 16, color: cp.course.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cp.course.code} - ${cp.course.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${cp.completedCount}/${cp.totalCount} hoàn thành (${cp.progressPercent.toStringAsFixed(0)}%)',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${cp.progressPercent.toStringAsFixed(0)}%',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cp.course.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: cp.totalCount > 0 ? (cp.completedCount / cp.totalCount) : 0.0,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cp.course.color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chi tiết phân bổ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bài giảng: ${cp.lectureCount}', style: const TextStyle(fontSize: 11)),
                        Text('Bài tập: ${cp.exerciseCount}', style: const TextStyle(fontSize: 11)),
                        Text('Tham khảo: ${cp.referenceCount}', style: const TextStyle(fontSize: 11)),
                        Text('Đề thi: ${cp.examCount}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // 4. Phân bố theo Phân loại tài liệu
          Text(
            'Phân bố theo Loại tài liệu',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: DocumentType.values.map((type) {
              final count = typeDistribution[type] ?? 0;
              return Expanded(
                child: Card(
                  elevation: 0,
                  color: type.color.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: type.color.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Column(
                      children: [
                        Icon(type.icon, color: type.color, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          '$count',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: type.color),
                        ),
                        Text(
                          type.label,
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 5. Quản lý Sao lưu Dữ liệu (Local-first Backup)
          Text(
            'Sao lưu & Xuất dữ liệu (Cashew Backup Strategy)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code_rounded, color: Colors.indigo),
                  title: const Text('Xuất dữ liệu định dạng JSON'),
                  subtitle: const Text('Toàn bộ CSDL môn học & tài liệu học tập'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    final json = BackupExportService.exportDatabaseToJson(
                      courses: provider.courses,
                      documents: provider.allDocuments,
                    );
                    _showExportDialog(
                      context,
                      title: 'Bản sao lưu CSDL (JSON)',
                      content: json,
                      fileType: 'JSON',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart_rounded, color: Colors.green),
                  title: const Text('Xuất bảng tính CSV'),
                  subtitle: const Text('Tương thích Microsoft Excel / Google Sheets'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    final csv = BackupExportService.exportDocumentsToCsv(
                      documents: provider.allDocuments,
                      courses: provider.courses,
                    );
                    _showExportDialog(
                      context,
                      title: 'Bảng dữ liệu tài liệu (CSV)',
                      content: csv,
                      fileType: 'CSV',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
