import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:take_home_assignment/provider/data_provider.dart';
import 'package:take_home_assignment/ui/widgets/main/csv_table.dart';
import 'package:take_home_assignment/ui/widgets/main/skeleton_table.dart';
import 'package:take_home_assignment/ui/widgets/main/top_bar.dart';

import '../widgets/filters/filter_sidebar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 280, child: FilterSidebar()),
                VerticalDivider(width: 1),
                Expanded(
                  child: Consumer<DataProvider>(
                    builder: (context, dp, _) {
                      if (dp.isLoading && dp.views.isEmpty) {
                        // initial load skeletons
                        return ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: 3,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, __) => const TableSkeleton(rows: 6),
                        );
                      }

                      if (!dp.isLoading && dp.views.isEmpty) {
                        return const Center(
                          child: Text('No data matches filters.'),
                        );
                      }
                      return Stack(
                        children: [
                          ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: dp.views.length,
                            separatorBuilder: (context, i) => SizedBox(
                              height: dp.views[i].rows.isEmpty ? 0 : 16,
                            ),
                            itemBuilder: (context, i) {
                              final v = dp.views[i];
                              if (v.rows.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return CsvTable(table: v.table, rows: v.rows);
                            },
                          ),
                          if (dp.isLoading)
                            const Align(
                              alignment: Alignment.topCenter,
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
