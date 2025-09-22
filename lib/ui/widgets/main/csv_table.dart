import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:provider/provider.dart';
import 'package:take_home_assignment/provider/data_provider.dart';
import 'package:take_home_assignment/styles/colors.dart';
import 'package:take_home_assignment/models/table_data_model.dart';
import 'package:take_home_assignment/ui/widgets/main/table_name_widget.dart';

class CsvTable extends StatefulWidget {
  final double height;
  final TableModel table;
  final List<List<String>> rows;

  const CsvTable({
    super.key,
    required this.table,
    required this.rows,
    required this.height,
  });

  @override
  State<CsvTable> createState() => _CsvTableState();
}

class _CsvTableState extends State<CsvTable>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dp = context.read<DataProvider>();
    final sort = context.watch<DataProvider>().getSort(widget.table.id);

    final safeRows = widget.rows.map((r) {
      final fixed = List<String>.from(r.map((e) => e));
      if (fixed.length < widget.table.headers.length) {
        fixed.addAll(
          List.filled(widget.table.headers.length - fixed.length, ''),
        );
      } else if (fixed.length > widget.table.headers.length) {
        fixed.removeRange(widget.table.headers.length, fixed.length);
      }
      return fixed;
    }).toList();

    const double headerH = 30;
    const double rowH = 30;
    double maxH = widget.height;

    final int rowCount = safeRows.length;
    final double tableH = (rowCount <= 10)
        ? headerH +
              rowH *
                  (rowCount == 0
                      ? 1
                      : rowCount) // show at least header+1 row height
        : maxH;

    if (safeRows.isEmpty) return const SizedBox.shrink();

    final cols = <DataColumn2>[
      for (var i = 0; i < widget.table.headers.length; i++)
        DataColumn2(
          label: Text(
            widget.table.headers[i],
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          onSort: (col, asc) => dp.setSort(widget.table.id, col, asc),
        ),
    ];

    return Card(
      elevation: 1,
      child: Column(
        children: [
          TableNameWidget(name: widget.table.displayName.toUpperCase()),
          Divider(height: 1),
          SizedBox(
            height: tableH,
            child: DataTable2(
              sortArrowIcon: Icons.arrow_drop_down,
              sortColumnIndex: sort?.$1,
              sortAscending: sort?.$2 ?? true,
              headingRowHeight: headerH,
              dataRowHeight: rowH,
              headingRowDecoration: const BoxDecoration(color: AppColors.bg),
              columns: cols,
              rows: safeRows
                  .take(500)
                  .map(
                    (r) => DataRow(
                      cells: r
                          .map(
                            (c) => DataCell(
                              Text(
                                c,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: widget.table.headers.length * 120,
            ),
          ),
        ],
      ),
    );
  }
}
