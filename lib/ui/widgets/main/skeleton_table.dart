import 'package:flutter/material.dart';

class TableSkeleton extends StatelessWidget {
  final int rows;
  const TableSkeleton({super.key, this.rows = 6});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.outline.withValues(alpha: .25)),
              ),
            ),
            child: _bar(cs),
          ),
          ...List.generate(rows, (_) => _row(cs)),
        ],
      ),
    );
  }

  Widget _bar(ColorScheme cs) => Container(
    width: 160,
    height: 14,
    decoration: BoxDecoration(
      color: cs.outline.withValues(alpha: .25),
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _row(ColorScheme cs) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: cs.surface,
      border: Border(
        bottom: BorderSide(color: cs.outline.withValues(alpha: .12)),
      ),
    ),
    child: Row(
      children: List.generate(
        5,
        (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 4 ? 0 : 8),
            height: 12,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ),
  );
}
