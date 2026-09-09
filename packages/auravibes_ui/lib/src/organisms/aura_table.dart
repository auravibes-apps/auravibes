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
    if (columns.isEmpty || rows.any((row) => row.length != columns.length)) {
      throw ArgumentError('Rows must match a non-empty list of columns.');
    }
    for (final cell in rows.expand((row) => row)) {
      if (cell != null &&
          cell is! String &&
          cell is! bool &&
          !(cell is num && cell.isFinite)) {
        throw ArgumentError('Table cells must be finite scalar values.');
      }
    }
    final theme = context.auraTheme;
    final sortedRows = _sortedRows(rows);
    final table = SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Table(
        children: [
          for (final (index, row) in [
            columns,
            ...sortedRows.map((row) => row.cells),
          ].indexed)
            TableRow(
              decoration: index == 0
                  ? BoxDecoration(color: context.auraColors.surfaceVariant)
                  : _rowDecoration(context, sortedRows[index - 1].index),
              children: [
                for (final (columnIndex, cell) in row.indexed)
                  Semantics(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: theme.spacing.sm,
                        horizontal: theme.spacing.md,
                      ),
                      child: _cell(index, columnIndex, cell),
                    ),
                    header: index == 0,
                    label: index == 0 || cell != null
                        ? null
                        : widget.noValueLabel,
                  ),
              ],
            ),
        ],
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: .new(
          horizontalInside: BorderSide(color: context.auraColors.outline),
        ),
        defaultVerticalAlignment: .middle,
      ),
    );
    final caption = widget.caption;
    final emptyText = rows.isEmpty ? widget.emptyText : null;
    if (caption == null && (emptyText == null || emptyText.isEmpty)) {
      return table;
    }

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: theme.spacing.sm,
      children: [
        if (caption case final value?) AuraText(child: value),
        table,
        if (emptyText case final value? when value.isNotEmpty)
          AuraText(child: Text(value), style: .bodySmall),
      ],
    );
  }

  List<({int index, List<Object?> cells})> _sortedRows(
    List<List<Object?>> rows,
  ) {
    final indexed = [
      for (final (index, row) in rows.indexed) (index: index, cells: row),
    ];
    final sortIndex = _sortIndex;
    if (sortIndex == null) {
      return indexed;
    }

    indexed.sort((left, right) {
      final result = _compare(left.cells[sortIndex], right.cells[sortIndex]);

      return _ascending ? result : -result;
    });

    return indexed;
  }

  int _compare(Object? left, Object? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    if (left is num && right is num) {
      return left.compareTo(right);
    }

    return left.toString().compareTo(right.toString());
  }

  BoxDecoration? _rowDecoration(BuildContext context, int rowIndex) {
    if (rowIndex >= widget.rowTints.length) {
      return null;
    }
    final tint = widget.rowTints[rowIndex];
    if (tint == null) {
      return null;
    }

    return BoxDecoration(
      color: context.auraColors.colorFor(tint).withValues(alpha: 0.08),
    );
  }

  Widget _cell(int rowIndex, int columnIndex, Object? cell) {
    if (rowIndex == 0) {
      final sortable =
          columnIndex < widget.sortableColumns.length &&
          widget.sortableColumns[columnIndex];
      final header = AuraText(child: Text(widget.columns[columnIndex]));
      if (!sortable) {
        return header;
      }

      return Semantics(
        child: GestureDetector(
          child: header,
          onTap: () => setState(() {
            _ascending = _sortIndex != columnIndex || !_ascending;
            _sortIndex = columnIndex;
          }),
        ),
        button: true,
      );
    }
    final format = columnIndex < widget.columnFormats.length
        ? widget.columnFormats[columnIndex]
        : AuraTableValueFormat.plain;
    final String rendered;
    if (cell == null) {
      rendered = String.fromCharCode(0x2014);
    } else if (cell is num && format == AuraTableValueFormat.percent) {
      rendered = '${(cell * 100).toStringAsFixed(0)}%';
    } else {
      rendered = cell.toString();
    }
    final alignment = columnIndex < widget.columnAlignments.length
        ? widget.columnAlignments[columnIndex]
        : AuraTableAlignment.start;

    return AuraText(
      child: Text(rendered),
      textAlign: switch (alignment) {
        .center => TextAlign.center,
        .end => TextAlign.end,
        .start => TextAlign.start,
      },
    );
  }
}
