import 'package:flutter/material.dart';
import 'filter_card_shell.dart';

class TextBoolFilterCard extends StatelessWidget {
  final String header;
  final ChipThemeData chipTheme;
  final List<String> options;
  final Set<String> selectedValues;
  final void Function(String value, bool isNow) onToggle;
  final VoidCallback onDelete;

  const TextBoolFilterCard({
    super.key,
    required this.header,
    required this.chipTheme,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titleRow = Row(
      children: [
        Expanded(
          child: Text(
            header.replaceAll('_', ' '),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Hide this filter',
          splashRadius: 16,
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          onPressed: onDelete,
        ),
      ],
    );

    return FilterCardShell(
      titleRow: titleRow,
      child: ChipTheme(
        data: chipTheme,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final selected = selectedValues.contains(opt);
            return FilterChip(
              showCheckmark: false,
              padding: EdgeInsets.zero,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(Icons.star_rounded, size: 12, color: cs.primary),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      opt,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, height: 1.0),
                    ),
                  ),
                ],
              ),
              selected: selected,
              onSelected: (isNow) => onToggle(opt, isNow),
            );
          }).toList(),
        ),
      ),
    );
  }
}
