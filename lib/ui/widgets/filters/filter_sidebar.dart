import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:take_home_assignment/models/column_schema.dart';
import 'package:take_home_assignment/ui/widgets/filters/date_filter_card.dart';
import 'package:take_home_assignment/ui/widgets/filters/number_filter_card.dart';
import 'package:take_home_assignment/ui/widgets/filters/text_bool_filter_card.dart';
import '../../../../provider/data_provider.dart';

typedef HeaderEntries = List<({String tableId, ColumnSchema schema})>;

class FilterSidebar extends StatefulWidget {
  const FilterSidebar({super.key});

  @override
  State<FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<FilterSidebar> {
  /// Session-only hidden headers; cleared on app restart.
  final Set<String> _hiddenHeaders = <String>{};

  ChipThemeData _chipTheme(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return ChipTheme.of(ctx).copyWith(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelStyle: TextStyle(color: cs.onSurface, fontSize: 11),
      selectedColor: cs.primary.withValues(alpha: .15),
      side: BorderSide(color: cs.outline.withValues(alpha: .3), width: .6),
      shape: const StadiumBorder(),
      elevation: 0,
      pressElevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final allTables = dp.tables.values.toList();
    final selectedTables = allTables
        .where((t) => dp.selectedTableIds.contains(t.id))
        .toList();

    // Group columns by header across selected tables.
    final Map<String, HeaderEntries> grouped = {};
    for (final t in selectedTables) {
      t.schemaByColumn.forEach((header, schema) {
        grouped.putIfAbsent(header, () => []);
        grouped[header]!.add((tableId: t.id, schema: schema));
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListView(
        children: [
          // header row
          const Row(
            children: [
              Text(
                'Tables',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // table toggles (compact)
          ...allTables.map(
            (t) => InkWell(
              onTap: () =>
                  dp.toggleTable(t.id, !dp.selectedTableIds.contains(t.id)),
              child: Row(
                children: [
                  Text(
                    t.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    dp.selectedTableIds.contains(t.id)
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 20),

          Row(
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                onPressed: () => dp.clearFilters(),
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              if (_hiddenHeaders.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => setState(_hiddenHeaders.clear),
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Restore', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),

          if (selectedTables.isEmpty)
            const Text(
              'Select a table to filter.',
              style: TextStyle(fontSize: 12),
            ),

          // Render one card per header (merged), skipping session-hidden
          if (selectedTables.isNotEmpty)
            ...grouped.entries
                .where((e) => !_hiddenHeaders.contains(e.key))
                .map((e) {
                  final header = e.key;
                  final entries = e.value;

                  // Decide dominant type if mixed: text > number > date
                  ColumnType type = entries.first.schema.type;
                  final types = entries.map((x) => x.schema.type).toSet();
                  if (types.length > 1) {
                    if (types.contains(ColumnType.text) ||
                        types.contains(ColumnType.boolean)) {
                      type = ColumnType.text;
                    } else if (types.contains(ColumnType.integer) ||
                        types.contains(ColumnType.decimal)) {
                      type = ColumnType.decimal;
                    } else {
                      type = ColumnType.date;
                    }
                  }

                  // Route to stateless cards
                  switch (type) {
                    case ColumnType.integer:
                    case ColumnType.decimal:
                      // merge schema ranges
                      double min0 = double.infinity, max0 = -double.infinity;
                      for (final e2 in entries) {
                        final s = e2.schema;
                        if (s.min != null) {
                          min0 = math.min(min0, s.min!.toDouble());
                        }
                        if (s.max != null) {
                          max0 = math.max(max0, s.max!.toDouble());
                        }
                      }
                      if (!min0.isFinite) min0 = 0;
                      if (!max0.isFinite) max0 = 1;

                      // merge current selection across tables
                      double? selMin, selMax;
                      for (final e2 in entries) {
                        final sel = dp.getNumberSelected(e2.tableId, header);
                        if (sel.min != null) {
                          selMin = (selMin == null)
                              ? sel.min!.toDouble()
                              : math.min(selMin, sel.min!.toDouble());
                        }
                        if (sel.max != null) {
                          selMax = (selMax == null)
                              ? sel.max!.toDouble()
                              : math.max(selMax, sel.max!.toDouble());
                        }
                      }

                      return NumberFilterCard(
                        header: header,
                        minValue: min0,
                        maxValue: max0,
                        startValue: selMin ?? min0,
                        endValue: selMax ?? max0,
                        onChanged: (lo, hi) {
                          for (final e2 in entries) {
                            dp.setNumberRange(e2.tableId, header, lo, hi);
                          }
                        },
                        onDelete: () =>
                            setState(() => _hiddenHeaders.add(header)),
                      );

                    case ColumnType.text:
                      return SizedBox();
                    case ColumnType.boolean:
                      final Set<String> options = {};
                      final Set<String> current = {};
                      for (final e2 in entries) {
                        options.addAll(
                          e2.schema.distinctValues ?? const <String>{},
                        );
                        current.addAll(dp.getTextSelected(e2.tableId, header));
                      }
                      return TextBoolFilterCard(
                        header: header,
                        chipTheme: _chipTheme(context),
                        options: options.toList()..sort(),
                        selectedValues: current,
                        onToggle: (value, isNow) {
                          final next = Set<String>.from(current);
                          isNow ? next.add(value) : next.remove(value);
                          for (final e2 in entries) {
                            dp.setTextFilter(e2.tableId, header, next);
                          }
                        },
                        onDelete: () =>
                            setState(() => _hiddenHeaders.add(header)),
                      );

                    case ColumnType.date:
                      // merge selected range (min of starts, max of ends)
                      DateTime? start, end;
                      for (final e2 in entries) {
                        final sel = dp.getDateSelected(e2.tableId, header);
                        if (sel.start != null) {
                          start = (start == null)
                              ? sel.start
                              : (sel.start!.isBefore(start)
                                    ? sel.start
                                    : start);
                        }
                        if (sel.end != null) {
                          end = (end == null)
                              ? sel.end
                              : (sel.end!.isAfter(end) ? sel.end : end);
                        }
                      }
                      return DateFilterCard(
                        header: header,
                        start: start,
                        end: end,
                        onPick: (range) {
                          for (final e2 in entries) {
                            dp.setDateRange(
                              e2.tableId,
                              header,
                              range?.start,
                              range?.end,
                            );
                          }
                        },
                        onClear: () {
                          for (final e2 in entries) {
                            dp.setDateRange(e2.tableId, header, null, null);
                          }
                        },
                        onDelete: () =>
                            setState(() => _hiddenHeaders.add(header)),
                      );
                  }
                }),
        ],
      ),
    );
  }
}
