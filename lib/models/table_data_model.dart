import 'package:take_home_assignment/models/column_schema.dart';

class TableModel {
  final String id;
  final String displayName;
  final List<String> headers;
  final List<List<String>> rows;
  final Map<String, ColumnSchema> schemaByColumn;

  const TableModel({
    required this.id,
    required this.displayName,
    required this.headers,
    required this.rows,
    required this.schemaByColumn,
  });
}
