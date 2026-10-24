/// Host-owned SQL fragments chosen from validated schema types.
class const WorkspaceRecordQuerySql(
  final String sortType,
  final String filterType, {
  required final bool descending,
  final bool contains = false,
  final bool referenceMultiple = false,
}) {
  String get _filter =>
      filterType == 'multiSelect' ||
          filterType == 'reference' && referenceMultiple
      ? 'jsonb_exists(filtered, @value)'
      : contains
      ? "strpos(translate(filtered#>>'{}', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), translate(@value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')) > 0"
      : switch (filterType) {
          'number' => "(filtered#>>'{}')::numeric = @value::numeric",
          'timestamp' =>
            "${_instant("filtered#>>'{}'")} = ${_instant('@value')}",
          'money' =>
            "filtered->>'currency' = @value::jsonb->>'currency' AND "
                "(filtered->>'amount')::numeric = (@value::jsonb->>'amount')::numeric",
          _ => "filtered#>>'{}' = @value",
        };
  String get _order {
    if (sortType == 'money') {
      return '${_ordered("(sorted->>'currency') COLLATE \"C\"")}, '
          '${_ordered("(sorted->>'amount')::numeric")}';
    }
    final expression = switch (sortType) {
      'number' => "(sorted#>>'{}')::numeric",
      'timestamp' => _instant("sorted#>>'{}'"),
      _ => "(sorted#>>'{}') COLLATE \"C\"",
    };

    return _ordered(expression);
  }

  String build() =>
      '''
WITH selected AS (
 SELECT "resourceId", data::jsonb->'values'->@sort AS sorted,
 data::jsonb->'values'->@filter AS filtered,
 data::jsonb->'values'->>@label AS label
 FROM workspace_resource
 WHERE "workspaceId" = @workspaceId AND "resourceKind" = 'tableRecord'
 AND "deletedAt" IS NULL AND data::jsonb->>'tableId' = @tableId
)
SELECT "resourceId" FROM selected
WHERE (@search = '' OR strpos(translate(label, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), @search) > 0)
AND (@filter = '' OR $_filter)
ORDER BY $_order, "resourceId" COLLATE "C" ASC
LIMIT @limit OFFSET @offset
''';
  String _ordered(String value) =>
      '$value ${descending ? 'DESC NULLS LAST' : 'ASC NULLS FIRST'}';
}

String _instant(String value) =>
    "substr(($value),1,19)||'.'||substr((CASE WHEN substr(($value),20,1)='.' "
    "THEN substr(($value),21,length(($value))-21) ELSE '' END)||'000000',1,6)||'Z'";
