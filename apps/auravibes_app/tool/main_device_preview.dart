import 'package:auravibes_app/main.dart' as app;
import 'package:device_preview/device_preview.dart';

Future<void> main() async {
  final _ = DevicePreview.enable();
  await app.main();
}
