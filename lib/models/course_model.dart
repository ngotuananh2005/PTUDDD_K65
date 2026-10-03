import 'package:flutter/material.dart';

/// Entity đại diện cho Môn học / Khóa học (Tương đương Category trong Cashew)
class CourseModel {
  final String courseId;
  final String name;
  final String code; // Mã môn học (ví dụ: CSE441)
  final String description;
  final Color color;
  final IconData icon;
  final int order;
  final DateTime dateCreated;

  const CourseModel({
    required this.courseId,
    required this.name,
    required this.code,
    this.description = '',
    required this.color,
    required this.icon,
    this.order = 0,
    required this.dateCreated,
  });

  CourseModel copyWith({
    String? courseId,
    String? name,
    String? code,
    String? description,
    Color? color,
    IconData? icon,
    int? order,
    DateTime? dateCreated,
  }) {
    return CourseModel(
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'name': name,
      'code': code,
      'description': description,
      'colorValue': color.value,
      'iconCodePoint': icon.codePoint,
      'orderIndex': order,
      'dateCreated': dateCreated.toIso8601String(),
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      courseId: map['courseId'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      description: (map['description'] as String?) ?? '',
      color: Color((map['colorValue'] as int?) ?? 0xFF1976D2),
      icon: IconData((map['iconCodePoint'] as int?) ?? Icons.school.codePoint, fontFamily: 'MaterialIcons'),
      order: (map['orderIndex'] as int?) ?? 0,
      dateCreated: DateTime.parse(map['dateCreated'] as String),
    );
  }
}
