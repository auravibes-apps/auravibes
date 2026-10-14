import 'package:auravibes_app/data/repositories/browser_session_repository.dart';
import 'package:auravibes_app/features/browser/services/browser_web_view_adapter.dart';
import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browser_session_providers.g.dart';

@Riverpod(keepAlive: true)
Future<BrowserSessionRepository> browserSessionRepository(Ref ref) async {
  return BrowserSessionRepository(
    await ref.watch(sharedPreferencesProvider.future),
  );
}

@Riverpod(keepAlive: true)
BrowserWebViewService browserWebViewService(Ref _) => BrowserWebViewAdapter();
