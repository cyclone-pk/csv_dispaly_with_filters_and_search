import 'package:flutter/material.dart';

class FilterCardShell extends StatelessWidget {
  final Widget titleRow;
  final Widget child;

  const FilterCardShell({
    super.key,
    required this.titleRow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: .25), width: .7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleRow, const SizedBox(height: 6), child],
      ),
    );
  }
}
