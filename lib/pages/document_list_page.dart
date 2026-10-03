import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document_type.dart';
import '../state/document_provider.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/course_chip.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/document_card.dart';
import 'add_edit_document_page.dart';
import 'document_detail_page.dart';

/// Màn hình Danh sách Tài liệu học tập kèm Tìm kiếm & Lọc đa tiêu chí
class DocumentListPage extends StatelessWidget {
  const DocumentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();

    final courses = provider.courses;
    final filteredDocuments = provider.filteredDocuments;
    final totalAll = provider.allDocuments.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Tài liệu Học tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Đặt lại bộ lọc',
            onPressed: () => provider.resetFilters(),
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
      body: Column(
        children: [
          // 1. Thanh tìm kiếm
          CustomSearchBarWidget(
            query: provider.searchQuery,
            onChanged: (val) => provider.setSearchQuery(val),
            onClear: () => provider.setSearchQuery(''),
          ),

          // 2. Bộ lọc Môn học (Courses Chip Bar)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                CourseChipWidget(
                  isSelected: provider.selectedCourseId == 'all',
                  label: 'Tất cả môn',
                  count: totalAll,
                  onTap: () => provider.setSelectedCourse('all'),
                ),
                ...courses.map((c) {
                  final count = provider.allDocuments.where((d) => d.courseId == c.courseId).length;
                  return CourseChipWidget(
                    course: c,
                    isSelected: provider.selectedCourseId == c.courseId,
                    label: c.code,
                    count: count,
                    onTap: () => provider.setSelectedCourse(c.courseId),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 3. Bộ lọc Loại tài liệu & Trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Filter theo DocumentType
                ...DocumentType.values.map((type) {
                  final isSelected = provider.selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(type.icon, size: 14, color: isSelected ? Colors.white : type.color),
                      label: Text(type.label, style: const TextStyle(fontSize: 11)),
                      selectedColor: type.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        provider.setSelectedType(selected ? type : null);
                      },
                    ),
                  );
                }),

                // Filter theo StudyStatus
                ...StudyStatus.values.map((st) {
                  final isSelected = provider.selectedStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(st.icon, size: 14, color: isSelected ? Colors.white : st.color),
                      label: Text(st.label, style: const TextStyle(fontSize: 11)),
                      selectedColor: st.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        provider.setSelectedStatus(selected ? st : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Header số lượng kết quả
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị: ${filteredDocuments.length} tài liệu',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (provider.searchQuery.isNotEmpty ||
                    provider.selectedCourseId != 'all' ||
                    provider.selectedType != null ||
                    provider.selectedStatus != null)
                  InkWell(
                    onTap: () => provider.resetFilters(),
                    child: Text(
                      'Xóa bộ lọc',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Danh sách tài liệu
          Expanded(
            child: filteredDocuments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy tài liệu phù hợp',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thử thay đổi từ khóa hoặc điều kiện bộ lọc',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => provider.resetFilters(),
                          child: const Text('Đặt lại bộ lọc'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: filteredDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocuments[index];
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
                        onStatusChange: (newStatus) => provider.updateStatus(doc.id, newStatus),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
