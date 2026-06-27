import 'package:url_launcher/url_launcher.dart';

Future<void> openSystemBrowser(Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) throw Exception('Could not launch $uri');
}
