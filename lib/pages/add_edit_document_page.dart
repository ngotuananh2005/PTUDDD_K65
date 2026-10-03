import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../models/document_model.dart';
import '../models/document_type.dart';
import '../state/document_provider.dart';

/// Màn hình Thêm mới hoặc Chỉnh sửa Tài liệu học tập
class AddEditDocumentPage extends StatefulWidget {
  final DocumentModel? documentToEdit;

  const AddEditDocumentPage({super.key, this.documentToEdit});

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _fileUrlController;
  late TextEditingController _pageCountController;
  late TextEditingController _estimatedMinutesController;
  late TextEditingController _tagsController;

  String? _selectedCourseId;
  DocumentType _selectedType = DocumentType.lecture;
  StudyStatus _selectedStatus = StudyStatus.pending;
  PriorityLevel _selectedPriority = PriorityLevel.medium;
  bool _isPinned = false;
  DateTime? _dueDate;

  bool get isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.documentToEdit;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _descriptionController =
        TextEditingController(text: doc?.description ?? '');
    _fileUrlController = TextEditingController(text: doc?.fileUrl ?? '');
    _pageCountController = TextEditingController(
        text: doc != null && doc.pageCount > 0 ? doc.pageCount.toString() : '');
    _estimatedMinutesController =
        TextEditingController(text: (doc?.estimatedMinutes ?? 30).toString());
    _tagsController = TextEditingController(text: doc?.tags.join(', ') ?? '');

    if (doc != null) {
      _selectedCourseId = doc.courseId;
      _selectedType = doc.type;
      _selectedStatus = doc.status;
      _selectedPriority = doc.priority;
      _isPinned = doc.isPinned;
      _dueDate = doc.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose();
    _pageCountController.dispose();
    _estimatedMinutesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _dueDate ?? now.add(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _saveDocument() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<DocumentProvider>();
    final courses = provider.courses;

    final courseId = _selectedCourseId ??
        (courses.isNotEmpty ? courses.first.courseId : 'general');

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final document = DocumentModel(
      id: widget.documentToEdit?.id ?? 'doc_${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      courseId: courseId,
      type: _selectedType,
      status: _selectedStatus,
      priority: _selectedPriority,
      fileUrl: _fileUrlController.text.trim(),
      pageCount: int.tryParse(_pageCountController.text.trim()) ?? 0,
      estimatedMinutes:
          int.tryParse(_estimatedMinutesController.text.trim()) ?? 30,
      isPinned: _isPinned,
      dateCreated: widget.documentToEdit?.dateCreated ?? now,
      dueDate: _dueDate,
      completedDate: _selectedStatus == StudyStatus.completed
          ? (widget.documentToEdit?.completedDate ?? now)
          : null,
      tags: tags,
    );

    provider.saveDocument(document);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isEditing ? 'Đã cập nhật tài liệu!' : 'Đã thêm tài liệu mới!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();
    final courses = provider.courses;

    if (_selectedCourseId == null && courses.isNotEmpty) {
      _selectedCourseId = courses.first.courseId;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa Tài liệu' : 'Thêm Tài liệu Mới'),
        actions: [
          TextButton.icon(
            onPressed: _saveDocument,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Lưu',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tiêu đề tài liệu
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề tài liệu *',
                hintText: 'Ví dụ: Bài giảng Chương 2 - Flutter State',
                prefixIcon: const Icon(Icons.title_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề tài liệu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Chọn Môn học
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Môn học *',
                prefixIcon: const Icon(Icons.school_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: courses.map((c) {
                return DropdownMenuItem<String>(
                  value: c.courseId,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: c.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${c.code} - ${c.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCourseId = val);
              },
            ),
            const SizedBox(height: 16),

            // Chọn Phân loại tài liệu (DocumentType)
            Text('Phân loại tài liệu', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DocumentType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  avatar: Icon(type.icon,
                      size: 16, color: isSelected ? Colors.white : type.color),
                  label: Text(type.label),
                  selected: isSelected,
                  selectedColor: type.color,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Chọn Trạng thái học tập
            Text('Trạng thái học tập', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<StudyStatus>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              segments: StudyStatus.values.map((st) {
                return ButtonSegment<StudyStatus>(
                  value: st,
                  label: Text(
                    st.label,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  icon: Icon(st.icon, size: 16),
                );
              }).toList(),
              selected: {_selectedStatus},
              onSelectionChanged: (set) {
                setState(() => _selectedStatus = set.first);
              },
            ),
            const SizedBox(height: 16),

            // Mức độ ưu tiên
            Text('Mức độ ưu tiên', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<PriorityLevel>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              segments: PriorityLevel.values.map((p) {
                return ButtonSegment<PriorityLevel>(
                  value: p,
                  label: Text(
                    p.label,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              selected: {_selectedPriority},
              onSelectionChanged: (set) {
                setState(() => _selectedPriority = set.first);
              },
            ),
            const SizedBox(height: 16),

            // Hạn nộp / Hạn chót
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              leading: const Icon(Icons.event_available_rounded),
              title: const Text('Hạn chót / Ngày cần hoàn thành'),
              subtitle: Text(
                _dueDate != null
                    ? DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_dueDate!)
                    : 'Chưa đặt hạn chót',
              ),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : const Icon(Icons.calendar_today_rounded, size: 20),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 16),

            // Số trang & Thời gian ước lượng (phút)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pageCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số trang',
                      prefixIcon: const Icon(Icons.find_in_page_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _estimatedMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Thời gian (phút)',
                      prefixIcon: const Icon(Icons.timer_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Đường dẫn URL / Tệp tin
            TextFormField(
              controller: _fileUrlController,
              decoration: InputDecoration(
                labelText: 'Link tài liệu / URL file',
                hintText: 'https://drive.google.com/... hoặc đường dẫn file',
                prefixIcon: const Icon(Icons.link_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Thẻ Tags
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Thẻ phân loại (cách nhau bởi dấu phẩy)',
                hintText: 'Flutter, State, Bài tập 1',
                prefixIcon: const Icon(Icons.tag_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Mô tả chi tiết
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú & Tóm tắt nội dung',
                hintText: 'Tóm tắt các kiến thức trọng tâm cần nhớ...',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Switch ghim yêu thích
            SwitchListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              title: const Text('Ghim tài liệu quan trọng'),
              subtitle: const Text(
                  'Hiển thị ưu tiên trên đầu danh sách và Dashboard'),
              secondary: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned ? theme.colorScheme.primary : null,
              ),
              value: _isPinned,
              onChanged: (val) => setState(() => _isPinned = val),
            ),

            const SizedBox(height: 24),

            // Nút Lưu
            FilledButton.icon(
              onPressed: _saveDocument,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save_rounded),
              label: Text(isEditing ? 'Cập nhật tài liệu' : 'Lưu tài liệu mới',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
