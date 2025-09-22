import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:take_home_assignment/services/csv_service.dart';
import '../../../../provider/data_provider.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Dynamic Multi-Table Search',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search across selected tables...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              onChanged: dp.setQuery,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              context.read<DataProvider>().addCsvsFromUpload();
            },
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload CSV', style: TextStyle(fontSize: 13)),
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: () => dp.loadFromAssets(),
          ),
        ],
      ),
    );
  }
}
