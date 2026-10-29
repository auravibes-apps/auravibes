import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

abstract final class WorkspaceTimeZones {
  static final List<String> _names = _initialize();

  static bool valid(String name) => _names.contains(name);
  static List<String> _initialize() {
    data.initializeTimeZones();

    return {'UTC', ...tz.timeZoneDatabase.locations.keys}.toList()..sort();
  }
}
