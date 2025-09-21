enum ColumnType { integer, decimal, boolean, date, text }

class ColumnSchema {
  final String name;
  final ColumnType type;
  final num? min;
  final num? max;
  final Set<String>? distinctValues;
  final bool nullable;

  const ColumnSchema({
    required this.name,
    required this.type,
    this.min,
    this.max,
    this.distinctValues,
    this.nullable = true,
  });
}
