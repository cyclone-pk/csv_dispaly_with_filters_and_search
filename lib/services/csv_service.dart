import 'dart:convert';
import 'dart:math' as math;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'package:http/http.dart' as http;
import 'package:take_home_assignment/models/column_schema.dart';

import 'package:take_home_assignment/models/table_data_model.dart';

class DataService {
  const DataService();

  // ────────────────────────────────────────────────────────────────────────────
  // I/O helpers (pure return values; no Provider/BuildContext dependency)
  // ────────────────────────────────────────────────────────────────────────────

  /// Load a CSV file bundled in assets and return (fileName, rawContent).
  Future<(String fileName, String content)> loadCsvFromAsset(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    return (assetPath.split('/').last, raw);
  }

  /// Pick a CSV from the browser / desktop (returns null if cancelled).
  Future<List<TableModel>> pickCsvsFromBrowser() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return [];

    final out = <TableModel>[];
    for (final f in result.files) {
      if (f.bytes == null) continue;
      final ext = _ext((f.extension ?? '').toLowerCase());
      final name = f.name;

      try {
        switch (ext) {
          case 'csv':
            out.add(_parseDelimitedText(name, utf8.decode(f.bytes!), ext));
            break;
          default:
            // ignore unsupported silently, or throw if you prefer
            break;
        }
      } catch (e) {
        // You could surface a toast/snackbar at call site if needed.
        print('Failed to parse $name: $e');
      }
    }
    return out;
  }

  /// Load a CSV from a URL and return (fileName, content).
  Future<(String fileName, String content)?> loadCsvFromUrl(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    return (url.split('/').last, utf8.decode(resp.bodyBytes));
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CSV parse → TableModel
  // ────────────────────────────────────────────────────────────────────────────

  /// Convert raw CSV text into headers/rows.
  ({List<String> headers, List<List<String>> rows}) parseCsv(
    String rawContent,
  ) {
    final parsed = const CsvToListConverter(eol: '\n').convert(rawContent);
    if (parsed.isEmpty) return (headers: <String>[], rows: <List<String>>[]);
    final headers = parsed.first.map((e) => e.toString()).toList();
    final rows = parsed
        .skip(1)
        .map((r) => r.map((e) => e?.toString() ?? '').toList())
        .toList();
    return (headers: headers, rows: rows);
  }

  /// Build a complete TableModel from a raw CSV.
  TableModel makeTable(
    String fileName,
    String rawContent, {
    int sampleLimit = 1000,
  }) {
    final parsed = parseCsv(rawContent);
    final schema = inferTableSchema(
      parsed.headers,
      parsed.rows,
      sampleLimit: sampleLimit,
    );
    return TableModel(
      id: fileName,
      displayName: fileName.replaceAll('.csv', ''),
      headers: parsed.headers,
      rows: parsed.rows,
      schemaByColumn: schema,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Schema inference (public)
  // ────────────────────────────────────────────────────────────────────────────

  Map<String, ColumnSchema> inferTableSchema(
    List<String> headers,
    List<List<String>> rows, {
    int sampleLimit = 1000,
  }) {
    final map = <String, ColumnSchema>{};
    final sampleRows = rows.take(sampleLimit);
    for (var c = 0; c < headers.length; c++) {
      final colName = headers[c];
      final colValues = sampleRows.map((r) => c < r.length ? (r[c]) : '');
      map[colName] = inferColumn(colName, colValues);
    }
    return map;
  }

  ColumnSchema inferColumn(String name, Iterable<String> sample) {
    int nonNull = 0;
    int intCount = 0, decCount = 0, boolCount = 0, dateCount = 0;
    num? minV, maxV;
    final freq = <String, int>{};

    for (final raw in sample) {
      final v = raw.trim();
      if (_isBlank(v)) continue;
      nonNull++;

      // frequency for chips
      freq[v] = (freq[v] ?? 0) + 1;

      // numeric?
      final n = parseNumLoose(v);
      if (n != null) {
        if (n is int || (n % 1 == 0)) {
          intCount++;
        } else {
          decCount++;
        }
        minV = (minV == null) ? n : math.min(n, minV);
        maxV = (maxV == null) ? n : math.max(n, maxV);
        continue;
      }

      // boolean?
      if (_boolLut.containsKey(v.toLowerCase())) {
        boolCount++;
        continue;
      }

      // date?
      if (tryDate(v) != null) {
        dateCount++;
        continue;
      }
    }

    if (nonNull == 0) {
      return ColumnSchema(name: name, type: ColumnType.text, nullable: true);
    }

    if (intCount >= nonNull * 0.7 && minV != null && maxV != null) {
      return ColumnSchema(
        name: name,
        type: ColumnType.integer,
        min: minV,
        max: maxV,
        nullable: nonNull < sample.length,
      );
    }
    if ((intCount + decCount) >= nonNull * 0.7 &&
        minV != null &&
        maxV != null) {
      return ColumnSchema(
        name: name,
        type: ColumnType.decimal,
        min: minV,
        max: maxV,
        nullable: nonNull < sample.length,
      );
    }
    if (boolCount >= nonNull * 0.7) {
      return ColumnSchema(
        name: name,
        type: ColumnType.boolean,
        distinctValues: {'true', 'false'},
        nullable: nonNull < sample.length,
      );
    }
    if (dateCount >= nonNull * 0.7) {
      return ColumnSchema(
        name: name,
        type: ColumnType.date,
        nullable: nonNull < sample.length,
      );
    }

    // fallback = text (top 30 distincts)
    final top = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final distincts = top.take(30).map((e) => e.key).toSet();
    return ColumnSchema(
      name: name,
      type: ColumnType.text,
      distinctValues: distincts,
      nullable: nonNull < sample.length,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Shared helpers (public so Provider can reuse)
  // ────────────────────────────────────────────────────────────────────────────

  /// Numbers with commas/currency removed.
  num? parseNumLoose(String s) {
    final cleaned = s.replaceAll(RegExp(r'[,\s\$€£₹]'), '');
    return num.tryParse(cleaned);
  }

  DateTime? tryDate(String s) => DateTime.tryParse(s);

  bool _isBlank(String? s) => s == null || s.trim().isEmpty;

  TableModel _parseDelimitedText(String fileName, String content, String ext) {
    final String delimiter = switch (ext) {
      'tsv' => '\t',
      'psv' => '|',
      _ => ',', // csv default
    };

    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      return TableModel(
        id: fileName,
        displayName: fileName.replaceAll('.$ext', ''),
        headers: const [],
        rows: const [],
        schemaByColumn: const {},
      );
    }

    // simple split respecting the chosen delimiter (no quotes support here);
    // if you need full CSV quoting for all delimiters, use csv package with a custom parser.
    List<String> splitLine(String l) =>
        l.split(delimiter).map((e) => e.trim()).toList();

    final headers = splitLine(lines.first);
    final rows = lines.skip(1).map(splitLine).toList();

    final schema = inferTableSchema(headers, rows);
    return TableModel(
      id: fileName,
      displayName: fileName.replaceAll('.$ext', ''),
      headers: headers,
      rows: rows,
      schemaByColumn: schema,
    );
  }

  TableModel _parseJsonArrayOrAuto(String fileName, String content) {
    final trimmed = content.trimLeft();
    if (trimmed.startsWith('[')) {
      // JSON array of objects
      final data = json.decode(content);
      if (data is! List) throw Exception('JSON is not an array');
      final maps = data
          .cast<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return _fromListOfMaps(fileName, maps);
    } else {
      // Try auto: NDJSON (one JSON object per line)
      return _parseNdjson(fileName, content);
    }
  }

  TableModel _parseNdjson(String fileName, String content) {
    final rowsMaps = <Map<String, dynamic>>[];
    for (final line in const LineSplitter().convert(content)) {
      final l = line.trim();
      if (l.isEmpty) continue;
      final obj = json.decode(l);
      if (obj is Map<String, dynamic>) {
        rowsMaps.add(obj);
      } else {
        throw Exception('NDJSON line is not an object');
      }
    }
    return _fromListOfMaps(fileName, rowsMaps);
  }

  List<TableModel> _parseXlsx(String fileName, Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final out = <TableModel>[];

    for (final sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName]!;
      if (table.rows.isEmpty) continue;

      // Convert excel rows -> String matrix
      final matrix = table.rows
          .map(
            (row) => row.map((cell) => (cell?.value ?? '').toString()).toList(),
          )
          .toList();

      // If first row seems like headers; else synthesize
      List<String> headers;
      List<List<String>> dataRows;
      if (_looksLikeHeaderRow(matrix.first)) {
        headers = matrix.first;
        dataRows = matrix.skip(1).toList();
      } else {
        final cols = (matrix.firstOrNull?.length ?? 0);
        headers = List.generate(cols, (i) => 'col_${i + 1}');
        dataRows = matrix;
      }

      final schema = inferTableSchema(headers, dataRows);
      out.add(
        TableModel(
          id: '$fileName::$sheetName',
          displayName: '${fileName.replaceAll('.xlsx', '')} • $sheetName',
          headers: headers,
          rows: dataRows,
          schemaByColumn: schema,
        ),
      );
    }
    return out;
  }

  // Convert a list of JSON maps into a flat table (dot-notated keys)
  TableModel _fromListOfMaps(String fileName, List<Map<String, dynamic>> maps) {
    // Collect all keys (flatten nested)
    final allKeys = <String>{};
    for (final m in maps) {
      _collectKeys('', m, allKeys);
    }
    final headers = allKeys.toList()..sort();

    String getVal(Map<String, dynamic> m, String k) {
      final v = _getNested(m, k);
      if (v == null) return '';
      if (v is num || v is bool) return v.toString();
      if (v is String) return v;
      return json.encode(v);
    }

    final rows = maps
        .map((m) => headers.map((k) => getVal(m, k)).toList())
        .toList();

    final schema = inferTableSchema(headers, rows);
    return TableModel(
      id: fileName,
      displayName: fileName.replaceAll(RegExp(r'\.(json|ndjson)$'), ''),
      headers: headers,
      rows: rows,
      schemaByColumn: schema,
    );
  }

  String _ext(String e) => e.trim();

  bool _looksLikeHeaderRow(List<String> row) {
    // heuristic: headers are short-ish and non-numeric
    int score = 0;
    for (final c in row) {
      final t = c.trim();
      if (t.isEmpty) continue;
      if (num.tryParse(t) == null) score++;
      if (t.length <= 24) score++;
    }
    return score >= (row.length); // loose heuristic
  }

  void _collectKeys(String prefix, Map<String, dynamic> map, Set<String> out) {
    map.forEach((k, v) {
      final key = prefix.isEmpty ? k : '$prefix.$k';
      if (v is Map<String, dynamic>) {
        _collectKeys(key, v, out);
      } else if (v is List) {
        // flatten simple lists by index (you can customize)
        for (var i = 0; i < v.length; i++) {
          final vi = v[i];
          if (vi is Map<String, dynamic>) {
            _collectKeys('$key[$i]', vi, out);
          } else {
            out.add('$key[$i]');
          }
        }
      } else {
        out.add(key);
      }
    });
  }

  dynamic _getNested(Map<String, dynamic> m, String dotted) {
    // Handles dot.notation and [idx]
    dynamic cur = m;
    final parts = dotted.split('.');
    for (final p in parts) {
      final arrMatch = RegExp(r'^([^\[]+)\[(\d+)\]$').firstMatch(p);
      if (arrMatch != null) {
        final base = arrMatch.group(1)!;
        final idx = int.parse(arrMatch.group(2)!);
        cur = (cur is Map ? cur[base] : null);
        if (cur is List && idx < cur.length) {
          cur = cur[idx];
        } else {
          return null;
        }
      } else {
        cur = (cur is Map ? cur[p] : null);
      }
      if (cur == null) return null;
    }
    return cur;
  }
}

// simple boolean LUT for inference
const _boolLut = {
  'true': true,
  'false': false,
  't': true,
  'f': false,
  '1': true,
  '0': false,
  'yes': true,
  'no': false,
  'y': true,
  'n': false,
};
