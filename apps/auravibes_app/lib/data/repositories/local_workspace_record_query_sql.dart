/// SQL fragments selected only from validated workspace column types.
class const LocalWorkspaceRecordQuerySql(
  final String sortType,
  final String filterType, {
  required final bool descending,
  final bool contains = false,
  final bool referenceMultiple = false,
}) {
  String get _filter {
    if (filterType == 'multiSelect' ||
        filterType == 'reference' && referenceMultiple) {
      return 'EXISTS (SELECT 1 FROM json_each(filtered) WHERE value = operand)';
    }
    if (contains) {
      return 'instr(lower(CAST(filtered AS TEXT)),lower(operand)) > 0';
    }

    return _equality;
  }

  String get _equality => switch (filterType) {
    'number' => 'filtered = CAST(operand AS NUMERIC)',
    'checkbox' => 'filtered = CAST(operand AS INTEGER)',
    'timestamp' => '${_instant('filtered')} = ${_instant('operand')}',
    'money' => const _Money('filtered').equals(const _Money('operand')),
    _ => 'CAST(filtered AS TEXT) = operand',
  };

  String get _order => switch (sortType) {
    'timestamp' => '${_instant('sorted')} $_direction',
    'money' => const _Money('sorted').order(descending: descending),
    _ => 'sorted $_direction',
  };
  String get _direction => descending ? 'DESC' : 'ASC';
  String build() =>
      '''
WITH selected AS (
 SELECT id, table_id, values_json, revision,
 json_extract(values_json, ?) AS label,
 json_extract(values_json, ?) AS filtered,
 json_extract(values_json, ?) AS sorted, ? AS operand
 FROM workspace_table_records
 WHERE workspace_id = ? AND table_id = ? AND deleted_at IS NULL
)
SELECT id, table_id, values_json, revision FROM selected
WHERE (? = '' OR instr(lower(CAST(label AS TEXT)), ?) > 0)
AND (? = '' OR $_filter)
ORDER BY $_order, id COLLATE BINARY ASC
LIMIT ? OFFSET ?
''';
}

String _instant(String value) =>
    "substr($value,1,19)||'.'||substr((CASE WHEN substr($value,20,1)='.' "
    "THEN substr($value,21,length($value)-21) ELSE '' END)||'000000',1,6)||'Z'";

class const _Money(final String value) {
  String get _currency => "json_extract($value, '\$.currency')";
  String get _amount => "json_extract($value, '\$.amount')";
  String get _magnitude =>
      "CASE WHEN substr($_amount,1,1)='-' THEN substr($_amount,2) "
      'ELSE $_amount END';
  String get _whole =>
      "CASE WHEN instr(($_magnitude),'.')=0 THEN ($_magnitude) "
      "ELSE substr(($_magnitude),1,instr(($_magnitude),'.')-1) END";
  String get _fraction =>
      "CASE WHEN instr(($_magnitude),'.')=0 THEN '' "
      "ELSE rtrim(substr(($_magnitude),instr(($_magnitude),'.')+1),'0') END";
  String get _negative =>
      "(substr($_amount,1,1)='-' AND (($_whole)!='0' OR ($_fraction)!=''))";

  String get _signedLength =>
      'CASE WHEN $_negative THEN -length(($_whole)) '
      'ELSE length(($_whole)) END';

  String equals(_Money other) =>
      '$_currency = ${other._currency} AND ($_whole) = (${other._whole}) '
      'AND ($_fraction) = (${other._fraction}) '
      'AND $_negative = ${other._negative}';

  String order({required bool descending}) {
    final forward = descending ? 'DESC' : 'ASC';
    final reverse = descending ? 'ASC' : 'DESC';

    return [
      '$_currency COLLATE BINARY $forward',
      'CASE WHEN $_negative THEN 0 ELSE 1 END $forward',
      '$_signedLength $forward',
      'CASE WHEN $_negative THEN ($_whole) END COLLATE BINARY $reverse',
      'CASE WHEN NOT $_negative THEN ($_whole) END COLLATE BINARY $forward',
      'CASE WHEN $_negative THEN ($_fraction) END COLLATE BINARY $reverse',
      'CASE WHEN NOT $_negative THEN ($_fraction) END COLLATE BINARY $forward',
    ].join(', ');
  }
}
