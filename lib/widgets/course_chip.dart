import 'package:flutter/material.dart';
import '../models/course_model.dart';

/// Widget hiển thị thẻ chọn Môn học (Filter Chip)
class CourseChipWidget extends StatelessWidget {
  final CourseModel? course;
  final bool isSelected;
  final String label;
  final int count;
  final VoidCallback onTap;

  const CourseChipWidget({
    super.key,
    this.course,
    required this.isSelected,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = course?.color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: course != null
            ? Icon(
                course!.icon,
                size: 16,
                color: isSelected ? Colors.white : color,
              )
            : Icon(
                Icons.apps_rounded,
                size: 16,
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
        selectedColor: color,
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        side: BorderSide(
          color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
