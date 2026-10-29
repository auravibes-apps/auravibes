import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

abstract final class WorkspaceTimeZones {
  static final List<String> names = _initialize();

  static bool valid(String name) => names.contains(name);
  static String display(String instant, String name) {
    final _ = names;

    return tz.TZDateTime.from(
      .parse(instant),
      name == 'UTC' ? tz.UTC : tz.getLocation(name),
    ).toIso8601String();
  }

  static List<String> _initialize() {
    data.initializeTimeZones();

    return {'UTC', ...tz.timeZoneDatabase.locations.keys}.toList()..sort();
  }
}
