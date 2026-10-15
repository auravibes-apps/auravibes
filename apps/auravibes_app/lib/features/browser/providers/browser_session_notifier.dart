import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toon_dart/toon_dart.dart';
import 'package:uuid/uuid.dart';

part 'browser_session_notifier.g.dart';
part 'browser_session_tool_lifecycle.dart';

const int _maxToolScreenshotBytes = 5 * 1024 * 1024;
const int _maxBrowserToolOutputCharacters = 16000;
const int _browserToolOutputPreviewCharacters = 15000;
const int _maxBrowserPageMarkupCharacters = 12000;
const int _maxBrowserQueryMarkupCharacters = 2400;
const int _maxBrowserSelectorCharacters = 256;
const int _minBrowserQueryMatches = 1;
const int _maxBrowserQueryMatches = 5;
const int _defaultBrowserFindLimit = 10;
const int _maxBrowserFindLimit = 10;
const int _defaultBrowserWaitMilliseconds = 5000;
const int _minBrowserWaitMilliseconds = 1;
const int _maxBrowserWaitMilliseconds = 30000;
const int _browserWaitPollMilliseconds = 100;
const int _maxBrowserScrollOffset = 10000;
const int _minBrowserScrollOffset = -_maxBrowserScrollOffset;
const int _maxBrowserFillCharacters = 16000;
const int _maxBrowserOptionCharacters = 256;
const int _maxBrowserToonContentCharacters = 10000;
const int _maxBrowserReadContentCharacters = 12000;
const int _browserPageUrlCharacters = 2048;
const int _browserPageTitleCharacters = 512;

typedef _BrowserScrollOffset = ({int x, int y});
typedef _BrowserScreenshotCapture = ({
  Uint8List? bytes,
  Map<Object?, Object?> snapshot,
});
typedef _BrowserElementTarget = ({
  String? selector,
  String? ref,
  String? snapshotId,
});
typedef _BrowserElementActionRequest = ({
  _BrowserElementTarget target,
  String action,
  String? text,
  String? optionValue,
  bool? checked,
});
typedef _BrowserTabClose = ({
  BrowserSessionState current,
  int index,
  String tabId,
});

typedef _BoundedIntegerOptions = ({
  String name,
  int defaultValue,
  int min,
  int max,
});

@riverpod
class BrowserSessionNotifier extends _$BrowserSessionNotifier
    with
        BrowserSessionToolLifecycle,
        BrowserSessionTabRefresh,
        BrowserSessionTabOperations,
        BrowserSessionToolTabNavigation,
        BrowserSessionToolControls,
        BrowserSessionTabStateUpdates,
        BrowserSessionToolDispatch,
        BrowserSessionToolPageActions,
        BrowserSessionPageInspection,
        BrowserSessionPageFindWait,
        BrowserSessionElementActions,
        BrowserSessionPageContent,
        BrowserSessionSnapshotMatching,
        BrowserSessionSkillToolRouter {
  @override
  Future<BrowserSessionState> build(
    String workspaceId,
    String conversationId,
  ) async {
    final session = await (await ref.watch(
      browserSessionRepositoryProvider.future,
    )).load(conversationId);
    if (session.tabs.isNotEmpty && !session.isSuspended) _retainSession();

    return session;
  }

  Future<void> openTab({String url = 'about:blank'}) async {
    _recordAgentActivity('open_tab');
    _retainSession();
    final current = _current;
    final tab = BrowserTab(id: const Uuid().v4(), url: url);
    await _save(
      current.copyWith(
        tabs: [...current.tabs, tab],
        activeTabId: tab.id,
        isSuspended: false,
      ),
    );
  }

  Future<void> selectTab(String tabId) async {
    final current = _current;
    _requireBrowserTab(current, tabId);
    if (current.isSuspended) _retainSession();
    await _save(current.copyWith(activeTabId: tabId, isSuspended: false));
    await _finishSelectingTab();
  }

  Future<void> closeTab(String tabId) async {
    final current = _current;
    final tabIndex = current.tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex < 0) return;

    await _closeBrowserTab(this, (
      current: current,
      index: tabIndex,
      tabId: tabId,
    ));
  }

  Future<void> closeAllTabs() async {
    final current = _current;
    if (current.tabs.isEmpty) return;

    await _removeRuntimeTabs(current);
    await _save(_emptyBrowserSession(current));
    _releaseSession();
  }

  Future<void> navigate(String url, {String? tabId}) async {
    final targetId = _targetTabId(tabId);
    final normalizedUrl = _normalizeUrl(url);
    await _runBrowserNavigation(this, (tabId: targetId, url: normalizedUrl));
  }

  Future<Object?> executeJavaScript(String source, {String? tabId}) async {
    if (source.trim().isEmpty) {
      throw ArgumentError.value(source, 'source', 'JavaScript is empty.');
    }

    final targetId = _targetTabId(tabId);
    _recordAgentActivity('running_javascript');
    final result = await _webViewService.controller.evaluateJavascript(
      sessionId: conversationId,
      tabId: targetId,
      source: source,
    );
    if (!ref.mounted) return result;
    _recordAgentActivity('ran_javascript');

    return result;
  }

  Future<bool> goBack({String? tabId}) =>
      _navigateHistory(tabId, backwards: true);

  Future<bool> goForward({String? tabId}) =>
      _navigateHistory(tabId, backwards: false);

  Future<void> reload({String? tabId}) async {
    if (tabId != null) await selectTab(tabId);
    final activeTabId = _targetTabId(tabId);
    final _ = _snapshotIdsByTab.remove(activeTabId);
    _recordAgentActivity('reloading');
    await _webViewService.controller.reload(
      sessionId: conversationId,
      tabId: activeTabId,
    );
    if (!ref.mounted) return;
    _recordAgentActivity('reloaded');
  }
}

Future<void> _closeBrowserTab(
  BrowserSessionNotifier notifier,
  _BrowserTabClose close,
) async {
  final current = close.current;
  final tabId = close.tabId;
  await notifier._removeRuntimeTab(tabId, current.isSuspended);
  final (:tabs, :activeTabId) = _browserTabsAfterClose(close);
  await notifier._save(_browserSessionAfterClose(current, tabs, activeTabId));
  await notifier._finishClosingTab(current, tabs, tabId);
}

Future<void> _runBrowserNavigation(
  BrowserSessionNotifier notifier,
  ({String tabId, String url}) navigation,
) async {
  notifier._recordAgentActivity('navigating');
  await notifier.updateTab(navigation.tabId, (
    url: navigation.url,
    title: null,
    isLoading: true,
    hasError: null,
    canGoBack: null,
    canGoForward: null,
  ));
  if (!notifier._isBrowserSessionMounted) return;

  await _performBrowserNavigation(notifier, navigation);
}

Future<void> _performBrowserNavigation(
  BrowserSessionNotifier notifier,
  ({String tabId, String url}) navigation,
) async {
  try {
    await notifier._webViewService.controller.navigate(
      sessionId: notifier.conversationId,
      tabId: navigation.tabId,
      url: navigation.url,
    );
  } on Object {
    if (!notifier._isBrowserSessionMounted) rethrow;
    await notifier._markNavigationFailed(navigation.tabId);
    rethrow;
  }
  if (!notifier._isBrowserSessionMounted) return;
  notifier._recordAgentActivity('navigated');
}

void _requireBrowserTab(BrowserSessionState current, String tabId) {
  if (current.tabs.any((tab) => tab.id == tabId)) return;

  throw ArgumentError.value(tabId, 'tabId', 'Unknown browser tab.');
}

({List<BrowserTab> tabs, String activeTabId}) _browserTabsAfterClose(
  _BrowserTabClose close,
) {
  final tabs = _browserTabsWithout(close.current, close.index);

  return (tabs: tabs, activeTabId: _activeBrowserTabAfterClose(close, tabs));
}

List<BrowserTab> _browserTabsWithout(
  BrowserSessionState current,
  int tabIndex,
) => [...current.tabs]..removeAt(tabIndex);

String _activeBrowserTabAfterClose(
  _BrowserTabClose close,
  List<BrowserTab> tabs,
) {
  if (tabs.isEmpty) return '';
  if (close.current.activeTabId != close.tabId) {
    return close.current.activeTabId;
  }
  final replacementIndex = close.index < tabs.length
      ? close.index
      : tabs.length - 1;

  return tabs[replacementIndex].id;
}

BrowserSessionState _browserSessionAfterClose(
  BrowserSessionState current,
  List<BrowserTab> tabs,
  String activeTabId,
) {
  if (tabs.isNotEmpty) {
    return current.copyWith(tabs: tabs, activeTabId: activeTabId);
  }

  return current.copyWith(
    tabs: tabs,
    activeTabId: activeTabId,
    isLoading: false,
    hasError: false,
    canGoBack: false,
    canGoForward: false,
    isSuspended: false,
  );
}

BrowserSessionState _emptyBrowserSession(BrowserSessionState current) =>
    current.copyWith(
      tabs: const [],
      activeTabId: '',
      isLoading: false,
      hasError: false,
      canGoBack: false,
      canGoForward: false,
      isSuspended: false,
    );

String _requiredString(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();

  throw FormatException('Browser tool requires a non-empty $key.');
}

Object? _boundedBrowserResult(Object? result) {
  if (result is String && result.length > _maxBrowserToolOutputCharacters) {
    return result.truncateCharacters(_maxBrowserToolOutputCharacters);
  }
  if (result is Map || result is List) {
    final encoded = jsonEncode(result);
    if (encoded.length > _maxBrowserToolOutputCharacters) {
      return {
        'truncated': true,
        'preview': encoded.truncateCharacters(
          _browserToolOutputPreviewCharacters,
        ),
      };
    }
  }

  return result;
}

String? _optionalTabId(Map<String, dynamic> arguments) =>
    _optionalString(arguments, 'tabId');

String? _optionalString(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value.trim();

  throw FormatException('Browser tool $key must be a non-empty string.');
}

int _boundedInteger(Object? value, _BoundedIntegerOptions options) {
  if (value == null) return options.defaultValue;
  if (value is int && value >= options.min && value <= options.max) {
    return value;
  }

  throw FormatException(
    'Browser tool ${options.name} must be between '
    '${options.min} and ${options.max}.',
  );
}

String _normalizeUrl(String input) {
  final value = input.trim();
  if (value.isEmpty) return 'about:blank';
  final uri = Uri.tryParse(value);
  if (uri?.hasScheme ?? false) return value;
  if (value.contains(' ') || !value.contains('.') && !value.contains(':')) {
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(value)}';
  }

  return 'https://$value';
}

String _normalizeAgentUrl(String input) {
  final normalized = _normalizeUrl(input);
  if (normalized == 'about:blank') return normalized;
  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      !const {'https', 'http'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    throw const FormatException(
      'Browser tools support HTTP, HTTPS, and about:blank URLs.',
    );
  }

  return normalized;
}
