import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:take_home_assignment/models/column_schema.dart';
import 'package:take_home_assignment/models/table_data_model.dart';
import 'package:take_home_assignment/services/csv_service.dart';

/// Lightweight view for rendering (table + filtered rows)
class TableView {
  final TableModel table;
  final List<List<String>> rows;
  const TableView(this.table, this.rows);
}

class DataProvider with ChangeNotifier {
  DataProvider({DataService? service}) : _svc = service ?? const DataService();
  final DataService _svc;
  final Map<String, TableModel> _tables = {};
  final Set<String> _selected = {};
  String _query = '';
  final Map<String, dynamic> _filters = {};
  final Map<String, (int columnIndex, bool ascending)> _sortState = {};
  final List<TableView> _views = [];
  bool _isLoading = false;
  Timer? _debounce;
  Map<String, TableModel> get tables => _tables;
  Set<String> get selectedTableIds => _selected;
  String get query => _query;
  Map<String, dynamic> get filters => _filters;
  List<TableView> get views => List.unmodifiable(_views);
  bool get isLoading => _isLoading;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadFromAssets() async {
    final files = <String>[
      // 'assets/csv_files/inventory.csv',
      // 'assets/csv_files/products.csv',
      // 'assets/csv_files/orders.csv',
      // 'assets/csv_files/users.csv',
    ];

    _tables.clear();
    _selected.clear();

    for (final path in files) {
      final (fileName, raw) = await _svc.loadCsvFromAsset(path);
      _addCsv(fileName, raw);
    }

    _selected.addAll(_tables.keys);
    _filters.clear();
    _query = '';

    _scheduleRecompute();
    notifyListeners();
  }

  Future<void> addCsvsFromUpload() async {
    _isLoading = true;
    notifyListeners();

    final tables = await _svc.pickCsvsFromBrowser();
    if (tables.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    for (final t in tables) {
      _tables[t.id] = t;
      _selected.add(t.id);
    }

    _scheduleRecompute();
    notifyListeners();
  }

  void _addCsv(String fileName, String rawContent) {
    final model = _svc.makeTable(fileName, rawContent);
    _tables[fileName] = model;
  }

  void toggleTable(String id, bool on) {
    if (on) {
      _selected.add(id);
    } else {
      _selected.remove(id);
    }
    _scheduleRecompute();
    notifyListeners();
  }

  void setQuery(String q) {
    _isLoading = true;
    notifyListeners();
    _query = q;
    _scheduleRecompute();
    notifyListeners();
  }

  void clearFilters() {
    _filters.clear();
    _query = '';
    _scheduleRecompute();
    notifyListeners();
  }

  void setNumberRange(String tableId, String column, num? min, num? max) {
    _isLoading = true;
    notifyListeners();
    _filters['$tableId::$column'] = {'type': 'number', 'min': min, 'max': max};
    _scheduleRecompute();
    notifyListeners();
  }

  void setTextFilter(String tableId, String column, Set<String> selected) {
    _isLoading = true;
    notifyListeners();
    _filters['$tableId::$column'] = {'type': 'text', 'selected': selected};
    _scheduleRecompute();
    notifyListeners();
  }

  void setDateRange(
    String tableId,
    String column,
    DateTime? start,
    DateTime? end,
  ) {
    _isLoading = true;
    notifyListeners();
    _filters['$tableId::$column'] = {
      'type': 'date',
      'start': start,
      'end': end,
    };
    _scheduleRecompute();
    notifyListeners();
  }

  (int columnIndex, bool ascending)? getSort(String tableId) =>
      _sortState[tableId];

  void setSort(String tableId, int columnIndex, bool ascending) {
    _isLoading = true;
    notifyListeners();
    _sortState[tableId] = (columnIndex, ascending);
    _scheduleRecompute();
    notifyListeners();
  }

  String _fKey(String tableId, String column) => '$tableId::$column';

  Set<String> getTextSelected(String tableId, String column) {
    final f = _filters[_fKey(tableId, column)];
    if (f is Map && f['type'] == 'text') {
      final s = f['selected'];
      if (s is Set<String>) return s;
    }
    return <String>{};
  }

  ({num? min, num? max}) getNumberSelected(String tableId, String column) {
    final f = _filters[_fKey(tableId, column)];
    if (f is Map && f['type'] == 'number') {
      return (min: f['min'] as num?, max: f['max'] as num?);
    }
    return (min: null, max: null);
  }

  ({DateTime? start, DateTime? end}) getDateSelected(
    String tableId,
    String column,
  ) {
    final f = _filters[_fKey(tableId, column)];
    if (f is Map && f['type'] == 'date') {
      return (start: f['start'] as DateTime?, end: f['end'] as DateTime?);
    }
    return (start: null, end: null);
  }

  void _scheduleRecompute() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 180),
      _recomputeFilteredViews,
    );
  }

  Future<void> _recomputeFilteredViews() async {
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final next = <TableView>[];
    final q = _query.trim().toLowerCase();
    for (final id in _selected) {
      final table = _tables[id];
      if (table == null) continue;

      final filteredRows = <List<String>>[];

      // Filtering
      for (final r in table.rows) {
        if (q.isNotEmpty && !r.any((cell) => cell.toLowerCase().contains(q))) {
          continue;
        }

        var pass = true;
        for (var c = 0; c < table.headers.length; c++) {
          final col = table.headers[c];
          final key = '$id::$col';
          final f = _filters[key];
          if (f == null) continue;

          final val = (c < r.length ? r[c] : '').trim();

          switch (f['type']) {
            case 'number':
              final n = _svc.parseNumLoose(val);
              final min = f['min'] as num?;
              final max = f['max'] as num?;
              if (n == null ||
                  (min != null && n < min) ||
                  (max != null && n > max)) {
                pass = false;
              }
              break;

            case 'text':
              final selected = f['selected'] as Set<String>;
              if (selected.isNotEmpty && !selected.contains(val)) {
                pass = false;
              }
              break;

            case 'date':
              final start = f['start'] as DateTime?;
              final end = f['end'] as DateTime?;
              final d = DateTime.tryParse(val);
              if (d == null ||
                  (start != null &&
                      d.isBefore(
                        DateTime(start.year, start.month, start.day),
                      )) ||
                  (end != null &&
                      d.isAfter(
                        DateTime(end.year, end.month, end.day, 23, 59, 59),
                      ))) {
                pass = false;
              }
              break;
          }
          if (!pass) break;
        }

        if (pass) filteredRows.add(r);
      }

      // Sorting (type-aware)
      final sort = _sortState[id];
      if (sort != null) {
        final colIdx = sort.$1;
        final asc = sort.$2;

        final header = (colIdx >= 0 && colIdx < table.headers.length)
            ? table.headers[colIdx]
            : null;
        final schema = header != null ? table.schemaByColumn[header] : null;
        final isNumeric =
            schema?.type == ColumnType.integer ||
            schema?.type == ColumnType.decimal;
        final isDate = schema?.type == ColumnType.date;

        filteredRows.sort((a, b) {
          final av = (colIdx < a.length ? a[colIdx] : '');
          final bv = (colIdx < b.length ? b[colIdx] : '');

          int cmp;
          if (isNumeric) {
            final an = _svc.parseNumLoose(av) ?? double.negativeInfinity;
            final bn = _svc.parseNumLoose(bv) ?? double.negativeInfinity;
            cmp = an.compareTo(bn);
          } else if (isDate) {
            final ad = DateTime.tryParse(av);
            final bd = DateTime.tryParse(bv);
            if (ad == null && bd == null) {
              cmp = 0;
            } else if (ad == null) {
              cmp = -1;
            } else if (bd == null) {
              cmp = 1;
            } else {
              cmp = ad.compareTo(bd);
            }
          } else {
            cmp = av.toLowerCase().compareTo(bv.toLowerCase());
          }
          return asc ? cmp : -cmp;
        });
      }

      next.add(TableView(table, filteredRows));
    }

    _views
      ..clear()
      ..addAll(next);

    _isLoading = false;
    notifyListeners();
  }
}
