import 'package:flutter/material.dart';

/// Widget Thanh tìm kiếm tuỳ biến với nút xóa và lọc nhanh
class CustomSearchBarWidget extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;

  const CustomSearchBarWidget({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClear,
    this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: query)
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: query.length),
                        ),
                      onChanged: onChanged,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm bài giảng, bài tập, môn học...',
                        hintStyle: TextStyle(fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClear,
                    ),
                ],
              ),
            ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: Badge(
                isLabelVisible: hasActiveFilters,
                child: const Icon(Icons.tune_rounded, size: 20),
              ),
              onPressed: onFilterTap,
              tooltip: 'Bộ lọc nâng cao',
            ),
          ],
        ],
      ),
    );
  }
}
