import 'package:decimal/decimal.dart';

/// Reduces already authorized scalar data without retaining records or IDs.
class A2uiDataSummary {
  new(this.types);
  final Map<String, String> types;
  final Map<String, _Summary> _columns = {};
  int _count = 0;

  void add(Map<String, Object?> values) {
    _count++;
    for (final entry in types.entries) {
      final value = values[entry.key];
      if (value == null) continue;
      (_columns[entry.key] ??= _Summary(entry.value)).add(value);
    }
  }

  Map<String, Object?> toJson() => {
    'count': _count,
    'columns': {
      for (final entry in types.entries)
        entry.key: (_columns[entry.key] ?? _Summary(entry.value)).toJson(),
    },
  };
}

class _Summary {
  new(this.type);
  final String type;
  final Map<String, _Range> _ranges = {};
  int _present = 0;

  void add(Object value) {
    _present++;
    if (type == 'money' && value is Map) {
      final currency = value['currency']! as String;
      (_ranges[currency] ??= _Range('number')).add(value['amount']! as Object);
    } else if (_ordered.contains(type)) {
      (_ranges[''] ??= _Range(type)).add(value);
    }
  }

  Map<String, Object?> toJson() => {
    'present': _present,
    if (type == 'money')
      'currencies': {
        for (final entry in _ranges.entries) entry.key: entry.value.toJson(),
      },
    if (type != 'money') ...?_ranges['']?.toJson(),
  };
}

const _ordered = {'number', 'money', 'dateOnly', 'timestamp'};

class _Range {
  new(this.type);
  final String type;
  Object? _minimum;
  Object? _maximum;
  Decimal? _sum;

  void add(Object value) {
    if (_minimum == null || _compare(value, _minimum!) < 0) _minimum = value;
    if (_maximum == null || _compare(value, _maximum!) > 0) _maximum = value;
    if (type == 'number') {
      _sum = (_sum ?? Decimal.zero) + Decimal.parse(value.toString());
    }
  }

  Map<String, Object?> toJson() => {
    'minimum': _minimum,
    'maximum': _maximum,
    if (_sum != null) 'sum': _sum.toString(),
  };

  int _compare(Object left, Object right) => switch (type) {
    'number' => Decimal.parse(
      left.toString(),
    ).compareTo(Decimal.parse(right.toString())),
    'timestamp' => DateTime.parse(
      left as String,
    ).compareTo(DateTime.parse(right as String)),
    _ => (left as String).compareTo(right as String),
  };
}
