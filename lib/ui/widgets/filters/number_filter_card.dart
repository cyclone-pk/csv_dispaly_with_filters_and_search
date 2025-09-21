import 'package:flutter/material.dart';
import 'package:take_home_assignment/ui/widgets/filters/custom_slider.dart';
import 'filter_card_shell.dart';

class NumberFilterCard extends StatelessWidget {
  final String header;
  final double minValue;
  final double maxValue;
  final double startValue;
  final double endValue;
  final void Function(double lo, double hi) onChanged;
  final VoidCallback onDelete;

  const NumberFilterCard({
    super.key,
    required this.header,
    required this.minValue,
    required this.maxValue,
    required this.startValue,
    required this.endValue,
    required this.onChanged,
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

    return FilterCardShell(
      titleRow: titleRow,
      child: MiniRangeSlider(
        thumbRadius: 2,
        start: startValue,
        end: endValue,
        min: minValue,
        max: maxValue,
        onChanged: onChanged,
      ),
    );
  }
}
