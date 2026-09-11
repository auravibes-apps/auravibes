import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/widgets.dart';

/// A read-only table that scrolls horizontally when its columns do not fit.
class AuraTable extends StatefulWidget {
  /// Creates a table of strings, finite numbers, booleans, or null cells.
  const new({
    required this.columns,
    required this.rows,
    super.key,
    this.caption,
    this.columnAlignments = const [],
    this.columnFormats = const [],
    this.sortableColumns = const [],
    this.rowTints = const [],
    this.emptyText,
    this.noValueLabel = 'No value',
  });

  /// Optional caller-localized caption above the table.
  final Widget? caption;

  /// Caller-localized column headings. At least one column is required.
  final List<String> columns;

  /// Scalar cells; each row must contain exactly one cell per column.
  /// Null displays as an empty cell. Preformat numbers for localized output.
  final List<List<Object?>> rows;

  /// Alignment for each column; omitted entries start-align.
  final List<AuraTableAlignment> columnAlignments;

  /// Display format for each column; omitted entries use plain text.
  final List<AuraTableValueFormat> columnFormats;

  /// Whether each header toggles a local scalar sort.
  final List<bool> sortableColumns;

  /// Optional semantic background tint for each data row.
  final List<AuraTint?> rowTints;

  /// Localized empty-data copy.
  final String? emptyText;

  /// Localized semantic description for null cells.
  final String noValueLabel;

  @override
  State<AuraTable> createState() => _AuraTableState();
}

/// Horizontal content alignment for a table column.
enum AuraTableAlignment {
  /// Start-align cells.
  start,

  /// Center cells.
  center,

  /// End-align cells.
  end,
}

/// Caller-selected scalar presentation without app-specific formatting.
enum AuraTableValueFormat {
  /// Render the scalar as supplied.
  plain,

  /// Render a numeric scalar.
  number,

  /// Render a normalized numeric scalar as a percentage.
  percent,
}

class _AuraTableState extends State<AuraTable> {
  int? _sortIndex;
  var _ascending = true;

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns;
    final rows = widget.rows;
    _validateRows(columns, rows);

    return _AuraTableLayout(
      table: widget,
      sortedRows: _sortedTableRows(rows, _sortIndex, _ascending),
      onSort: _sort,
    );
  }

  void _sort(int columnIndex) {
    setState(() {
      _ascending = _sortIndex != columnIndex || !_ascending;
      _sortIndex = columnIndex;
    });
  }
}

typedef _IndexedTableRow = ({int index, List<Object?> cells});

typedef _CompareRowsRequest = ({
  _IndexedTableRow left,
  _IndexedTableRow right,
  int sortIndex,
  bool ascending,
});

typedef _TableRowRequest = ({
  BuildContext context,
  bool isHeader,
  int rowIndex,
  Iterable<Object?> cells,
});

typedef _TableCellFrameRequest = ({
  AuraTable table,
  bool isHeader,
  int columnIndex,
  Object? cell,
  ValueChanged<int> onSort,
});

typedef _TableCellData = ({
  bool isHeader,
  String header,
  Object? cell,
  AuraTableValueFormat format,
  AuraTableAlignment alignment,
  VoidCallback? onSort,
});

void _validateRows(List<String> columns, List<List<Object?>> rows) {
  if (_hasInvalidTableRows(columns, rows)) {
    throw ArgumentError('Rows must match a non-empty list of columns.');
  }
}

bool _hasInvalidTableRows(List<String> columns, List<List<Object?>> rows) =>
    _hasInvalidTableShape(columns, rows) ||
    rows.expand((row) => row).any(_hasInvalidTableCell);

bool _hasInvalidTableShape(List<String> columns, List<List<Object?>> rows) =>
    columns.isEmpty || rows.any((row) => row.length != columns.length);

bool _hasInvalidTableCell(Object? cell) => switch (cell) {
  null || String() || bool() => false,
  final num value => !value.isFinite,
  _ => true,
};

List<_IndexedTableRow> _sortedTableRows(
  List<List<Object?>> rows,
  int? sortIndex,
  bool ascending,
) {
  final indexed = _indexedTableRows(rows);
  if (sortIndex == null) return indexed;

  _sortTableRows(indexed, sortIndex, ascending);

  return indexed;
}

List<_IndexedTableRow> _indexedTableRows(List<List<Object?>> rows) => [
  for (final (index, row) in rows.indexed) (index: index, cells: row),
];

void _sortTableRows(
  List<_IndexedTableRow> rows,
  int sortIndex,
  bool ascending,
) => rows.sort(
  (left, right) => _compareSortedRows((
    left: left,
    right: right,
    sortIndex: sortIndex,
    ascending: ascending,
  )),
);

int _compareSortedRows(_CompareRowsRequest request) {
  final result = _compareTableCells(
    request.left.cells[request.sortIndex],
    request.right.cells[request.sortIndex],
  );

  return request.ascending ? result : -result;
}

int _compareTableCells(Object? left, Object? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  if (left is num && right is num) return left.compareTo(right);

  return left.toString().compareTo(right.toString());
}

class const _AuraTableLayout({
  required final AuraTable table,
  required final List<_IndexedTableRow> sortedRows,
  required final ValueChanged<int> onSort,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraTableLayoutContent(
    content: _AuraTableTable(
      table: table,
      sortedRows: sortedRows,
      onSort: onSort,
    ),
    caption: table.caption,
    emptyText: _emptyTableText(table),
  );
}

class const _AuraTableLayoutContent({
  required final Widget content,
  required final Widget? caption,
  required final String? emptyText,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (caption == null && emptyText?.isNotEmpty != true) {
      return content;
    }

    return _AuraTableExtras(
      caption: caption,
      emptyText: emptyText,
      content: content,
    );
  }
}

String? _emptyTableText(AuraTable table) =>
    table.rows.isEmpty ? table.emptyText : null;

class _AuraTableExtras extends StatelessWidget {
  new({
    required Widget? caption,
    required String? emptyText,
    required this.content,
  }) : _children = [
         if (caption case final value?) AuraText(child: value),
         content,
         if (emptyText case final value? when value.isNotEmpty)
           AuraText(child: Text(value), style: .bodySmall),
       ];

  final Widget content;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    spacing: context.auraTheme.spacing.sm,
    children: _children,
  );
}

class _AuraTableTable extends StatelessWidget {
  const new({
    required this.table,
    required this.sortedRows,
    required this.onSort,
  });

  final AuraTable table;
  final List<_IndexedTableRow> sortedRows;
  final ValueChanged<int> onSort;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Table(
        children: _rows(context),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: .new(
          horizontalInside: BorderSide(color: context.auraColors.outline),
        ),
        defaultVerticalAlignment: .middle,
      ),
    );
  }

  List<TableRow> _rows(BuildContext context) => [
    _headerRow(context),
    for (final row in sortedRows) _dataRow(context, row),
  ];

  TableRow _headerRow(BuildContext context) => _row((
    context: context,
    isHeader: true,
    rowIndex: 0,
    cells: table.columns,
  ));

  TableRow _dataRow(BuildContext context, _IndexedTableRow row) => _row((
    context: context,
    isHeader: false,
    rowIndex: row.index,
    cells: row.cells,
  ));

  TableRow _row(_TableRowRequest request) => TableRow(
    decoration: _rowDecorationFor(request),
    children: [
      for (final (columnIndex, cell) in request.cells.indexed)
        _AuraTableCellFrame(
          table: table,
          isHeader: request.isHeader,
          columnIndex: columnIndex,
          cell: cell,
          onSort: onSort,
        ),
    ],
  );

  BoxDecoration? _rowDecorationFor(_TableRowRequest request) => request.isHeader
      ? BoxDecoration(color: request.context.auraColors.surfaceVariant)
      : _rowDecoration(request.context, request.rowIndex);

  BoxDecoration? _rowDecoration(BuildContext context, int rowIndex) {
    if (rowIndex >= table.rowTints.length) return null;
    final tint = table.rowTints[rowIndex];
    if (tint == null) return null;

    return BoxDecoration(
      color: context.auraColors.colorFor(tint).withValues(alpha: 0.08),
    );
  }
}

class const _AuraTableCellFrame({
  required final AuraTable table,
  required final bool isHeader,
  required final int columnIndex,
  required final Object? cell,
  required final ValueChanged<int> onSort,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = _tableCellFrameData((
      table: table,
      isHeader: isHeader,
      columnIndex: columnIndex,
      cell: cell,
      onSort: onSort,
    ));

    return _AuraTableCellSemantics(
      data: data,
      child: _AuraTableCellFrameContent(data: data),
    );
  }
}

typedef _TableCellFrameData = ({
  AuraTable table,
  bool isHeader,
  int columnIndex,
  Object? cell,
  String? label,
  VoidCallback? onSort,
});

_TableCellFrameData _tableCellFrameData(_TableCellFrameRequest request) {
  final table = request.table;

  return (
    table: table,
    isHeader: request.isHeader,
    columnIndex: request.columnIndex,
    cell: request.cell,
    label: _tableCellLabel(request),
    onSort: _tableCellSortCallback(request),
  );
}

String? _tableCellLabel(_TableCellFrameRequest request) =>
    request.isHeader || request.cell != null
    ? null
    : request.table.noValueLabel;

VoidCallback? _tableCellSortCallback(_TableCellFrameRequest request) {
  if (!_isTableCellSortable(
    request.table,
    request.isHeader,
    request.columnIndex,
  )) {
    return null;
  }

  return () => request.onSort(request.columnIndex);
}

bool _isTableCellSortable(AuraTable table, bool isHeader, int columnIndex) =>
    isHeader &&
    columnIndex < table.sortableColumns.length &&
    table.sortableColumns[columnIndex];

class const _AuraTableCellSemantics({
  required final _TableCellFrameData data,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Semantics(child: child, header: data.isHeader, label: data.label);
}

class const _AuraTableCellFrameContent({
  required final _TableCellFrameData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: context.auraTheme.spacing.sm,
      horizontal: context.auraTheme.spacing.md,
    ),
    child: _AuraTableCellValue(data: data),
  );
}

class const _AuraTableCellValue({required final _TableCellFrameData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final table = data.table;
    final columnIndex = data.columnIndex;

    return _AuraTableCell(
      isHeader: data.isHeader,
      header: table.columns[columnIndex],
      cell: data.cell,
      format: _tableColumnFormat(table, columnIndex),
      alignment: _tableColumnAlignment(table, columnIndex),
      onSort: data.onSort,
    );
  }
}

AuraTableValueFormat _tableColumnFormat(AuraTable table, int columnIndex) =>
    columnIndex < table.columnFormats.length
    ? table.columnFormats[columnIndex]
    : AuraTableValueFormat.plain;

AuraTableAlignment _tableColumnAlignment(AuraTable table, int columnIndex) =>
    columnIndex < table.columnAlignments.length
    ? table.columnAlignments[columnIndex]
    : AuraTableAlignment.start;

class const _AuraTableCell({
  required final bool isHeader,
  required final String header,
  required final Object? cell,
  required final AuraTableValueFormat format,
  required final AuraTableAlignment alignment,
  final VoidCallback? onSort,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraTableCellBody(
    data: (
      isHeader: isHeader,
      header: header,
      cell: cell,
      format: format,
      alignment: alignment,
      onSort: onSort,
    ),
  );
}

class const _AuraTableCellBody({required final _TableCellData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraTableCellInteraction(
    content: _AuraTableCellContent(data: data),
    onSort: data.onSort,
  );
}

class const _AuraTableCellContent({required final _TableCellData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => data.isHeader
      ? AuraText(child: Text(data.header))
      : _AuraTableValueCell(
          cell: data.cell,
          format: data.format,
          alignment: data.alignment,
        );
}

class const _AuraTableCellInteraction({
  required final Widget content,
  required final VoidCallback? onSort,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callback = onSort;
    if (callback == null) return content;

    return Semantics(
      child: GestureDetector(child: content, onTap: callback),
      button: true,
    );
  }
}

class const _AuraTableValueCell({
  required final Object? cell,
  required final AuraTableValueFormat format,
  required final AuraTableAlignment alignment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(_renderTableValue(cell, format)),
    textAlign: _tableTextAlignment(alignment),
  );
}

String _renderTableValue(Object? cell, AuraTableValueFormat format) {
  if (cell == null) return String.fromCharCode(0x2014);
  if (cell is num && format == AuraTableValueFormat.percent) {
    return '${(cell * 100).toStringAsFixed(0)}%';
  }

  return cell.toString();
}

TextAlign _tableTextAlignment(AuraTableAlignment alignment) =>
    switch (alignment) {
      .center => TextAlign.center,
      .end => TextAlign.end,
      .start => TextAlign.start,
    };
