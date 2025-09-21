import 'package:flutter/material.dart';
import 'filter_card_shell.dart';

class DateFilterCard extends StatelessWidget {
  final String header;
  final DateTime? start;
  final DateTime? end;
  final void Function(DateTimeRange? range) onPick;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  const DateFilterCard({
    super.key,
    required this.header,
    required this.start,
    required this.end,
    required this.onPick,
    required this.onClear,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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

    final summary = [
      if (start != null) _fmt(start!),
      if (end != null) _fmt(end!),
    ].join(' → ');

    return FilterCardShell(
      titleRow: titleRow,
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary.isEmpty ? 'Any date' : summary,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          IconButton(
            tooltip: 'Pick',
            icon: const Icon(Icons.date_range, size: 18),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(1970),
                lastDate: DateTime(2100),
                initialDateRange: (start != null || end != null)
                    ? DateTimeRange(
                        start: start ?? DateTime.now(),
                        end: end ?? DateTime.now(),
                      )
                    : null,
              );
              onPick(picked);
            },
          ),
          if (start != null || end != null)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.clear, size: 18),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}
