import 'package:flutter/material.dart';

/// Các phân loại tài liệu học tập trong hệ thống
enum DocumentType {
  lecture('Bài giảng', Icons.menu_book_rounded, Color(0xFF1E88E5)),
  exercise('Bài tập', Icons.assignment_rounded, Color(0xFFFB8C00)),
  reference('Tài liệu tham khảo', Icons.library_books_rounded, Color(0xFF43A047)),
  exam('Đề thi / Kiểm tra', Icons.quiz_rounded, Color(0xFFE53935));

  final String label;
  final IconData icon;
  final Color color;

  const DocumentType(this.label, this.icon, this.color);

  static DocumentType fromString(String? value) {
    if (value == null) return DocumentType.lecture;
    return DocumentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DocumentType.lecture,
    );
  }
}

/// Trạng thái học tập của tài liệu
enum StudyStatus {
  pending('Chưa học', Icons.schedule_rounded, Color(0xFF757575)),
  inProgress('Đang học', Icons.timelapse_rounded, Color(0xFF0288D1)),
  completed('Đã hoàn thành', Icons.check_circle_rounded, Color(0xFF2E7D32));

  final String label;
  final IconData icon;
  final Color color;

  const StudyStatus(this.label, this.icon, this.color);

  static StudyStatus fromString(String? value) {
    if (value == null) return StudyStatus.pending;
    return StudyStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StudyStatus.pending,
    );
  }
}

/// Mức độ ưu tiên của tài liệu
enum PriorityLevel {
  low('Thấp', Color(0xFF9E9E9E)),
  medium('Trung bình', Color(0xFFFBC02D)),
  high('Quan trọng / Gấp', Color(0xFFE53935));

  final String label;
  final Color color;

  const PriorityLevel(this.label, this.color);

  static PriorityLevel fromString(String? value) {
    if (value == null) return PriorityLevel.medium;
    return PriorityLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PriorityLevel.medium,
    );
  }
}
