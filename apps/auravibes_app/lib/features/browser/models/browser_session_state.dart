typedef BrowserTabUpdate = ({
  String? url,
  String? title,
  bool? isLoading,
  bool? hasError,
  bool? canGoBack,
  bool? canGoForward,
});
typedef _BrowserSessionUpdate = ({
  List<BrowserTab>? tabs,
  String? activeTabId,
  List<WorkspaceContentTab>? workspaceTabs,
  String? selectedWorkspaceTabId,
  bool clearSelectedWorkspaceTab,
  bool? isLoading,
  bool? hasError,
  bool? canGoBack,
  bool? canGoForward,
  bool? isSuspended,
  String? agentActivity,
  int? agentActionRevision,
  bool clearAgentActivity,
});
typedef _BrowserSessionTabs = ({
  List<BrowserTab> tabs,
  String activeTabId,
  List<WorkspaceContentTab> workspaceTabs,
  String? selectedWorkspaceTabId,
});
typedef _BrowserSessionMetadata = ({
  bool isSuspended,
  String? agentActivity,
  int agentActionRevision,
});

class const BrowserSessionState({
  required final List<BrowserTab> tabs,
  required final String activeTabId,
  final List<WorkspaceContentTab> workspaceTabs = const [],
  final String? selectedWorkspaceTabId,
  final bool isLoading = false,
  final bool hasError = false,
  final bool canGoBack = false,
  final bool canGoForward = false,
  final bool isSuspended = false,
  final String? agentActivity,
  final int agentActionRevision = 0,
}) {
  factory initial() => const BrowserSessionState(tabs: [], activeTabId: '');

  factory fromJson(Map<String, dynamic> json) => _browserSessionFromJson(json);

  BrowserTab? get activeTab =>
      tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  Map<String, Object?> toJson() => {
    'tabs': tabs.map((tab) => tab.toJson()).toList(),
    'activeTabId': activeTabId,
    'isSuspended': isSuspended,
    'workspaceTabs': workspaceTabs.map((tab) => tab.toJson()).toList(),
    'selectedWorkspaceTabId': selectedWorkspaceTabId,
  };

  BrowserSessionState copyWith({
    List<BrowserTab>? tabs,
    String? activeTabId,
    List<WorkspaceContentTab>? workspaceTabs,
    String? selectedWorkspaceTabId,
    bool clearSelectedWorkspaceTab = false,
    bool? isLoading,
    bool? hasError,
    bool? canGoBack,
    bool? canGoForward,
    bool? isSuspended,
    String? agentActivity,
    int? agentActionRevision,
    bool clearAgentActivity = false,
  }) => _copyBrowserSession(this, (
    tabs: tabs,
    activeTabId: activeTabId,
    workspaceTabs: workspaceTabs,
    selectedWorkspaceTabId: selectedWorkspaceTabId,
    clearSelectedWorkspaceTab: clearSelectedWorkspaceTab,
    isLoading: isLoading,
    hasError: hasError,
    canGoBack: canGoBack,
    canGoForward: canGoForward,
    isSuspended: isSuspended,
    agentActivity: agentActivity,
    agentActionRevision: agentActionRevision,
    clearAgentActivity: clearAgentActivity,
  ));
}

BrowserSessionState _browserSessionFromJson(Map<String, dynamic> json) {
  _validateBrowserSessionJson(json);
  final tabs = _decodeBrowserTabs(json['tabs'] as List<Object?>);
  final workspaceTabs = _decodeWorkspaceContentTabs(
    json['workspaceTabs'] as List<Object?>? ?? const [],
  );

  return _restoreBrowserSession(
    tabs,
    workspaceTabs,
    json,
  );
}

BrowserSessionState _restoreBrowserSession(
  List<BrowserTab> tabs,
  List<WorkspaceContentTab> workspaceTabs,
  Map<String, dynamic> json,
) {
  return BrowserSessionState(
    tabs: tabs,
    activeTabId: _activeBrowserTab(tabs, json['activeTabId'] as String?),
    workspaceTabs: workspaceTabs,
    selectedWorkspaceTabId: _selectedWorkspaceTab(
      workspaceTabs,
      json['selectedWorkspaceTabId'] as String?,
    ),
    isSuspended: json['isSuspended'] as bool? ?? false,
  );
}

String _activeBrowserTab(List<BrowserTab> tabs, String? id) =>
    tabs.where((tab) => tab.id == id).firstOrNull?.id ??
    tabs.firstOrNull?.id ??
    '';

String? _selectedWorkspaceTab(List<WorkspaceContentTab> tabs, String? id) =>
    id == 'chooser' || tabs.any((tab) => tab.key == id) ? id : null;

BrowserSessionState _copyBrowserSession(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) {
  final tabs = _copyBrowserSessionTabs(current, update);
  final navigation = _copyBrowserNavigation(current, update);
  final metadata = _copyBrowserSessionMetadata(current, update);

  return _browserSessionFromUpdates(tabs, navigation, metadata);
}

BrowserSessionState _browserSessionFromUpdates(
  _BrowserSessionTabs tabs,
  ({bool isLoading, bool hasError, bool canGoBack, bool canGoForward})
  navigation,
  _BrowserSessionMetadata metadata,
) => BrowserSessionState(
  tabs: tabs.tabs,
  activeTabId: tabs.activeTabId,
  workspaceTabs: tabs.workspaceTabs,
  selectedWorkspaceTabId: tabs.selectedWorkspaceTabId,
  isLoading: navigation.isLoading,
  hasError: navigation.hasError,
  canGoBack: navigation.canGoBack,
  canGoForward: navigation.canGoForward,
  isSuspended: metadata.isSuspended,
  agentActivity: metadata.agentActivity,
  agentActionRevision: metadata.agentActionRevision,
);

_BrowserSessionTabs _copyBrowserSessionTabs(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) => (
  tabs: update.tabs ?? current.tabs,
  activeTabId: update.activeTabId ?? current.activeTabId,
  workspaceTabs: update.workspaceTabs ?? current.workspaceTabs,
  selectedWorkspaceTabId: update.clearSelectedWorkspaceTab
      ? null
      : update.selectedWorkspaceTabId ?? current.selectedWorkspaceTabId,
);

({bool isLoading, bool hasError, bool canGoBack, bool canGoForward})
_copyBrowserNavigation(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) => (
  isLoading: update.isLoading ?? current.isLoading,
  hasError: update.hasError ?? current.hasError,
  canGoBack: update.canGoBack ?? current.canGoBack,
  canGoForward: update.canGoForward ?? current.canGoForward,
);

_BrowserSessionMetadata _copyBrowserSessionMetadata(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) => (
  isSuspended: update.isSuspended ?? current.isSuspended,
  agentActivity: update.clearAgentActivity
      ? null
      : update.agentActivity ?? current.agentActivity,
  agentActionRevision:
      update.agentActionRevision ?? current.agentActionRevision,
);

void _validateBrowserSessionJson(Map<String, dynamic> json) {
  if (json['tabs'] is! List ||
      !_optional<String>(json['activeTabId']) ||
      !_optional<List<Object?>>(json['workspaceTabs']) ||
      !_optional<String>(json['selectedWorkspaceTabId']) ||
      !_optional<bool>(json['isSuspended'])) {
    throw const FormatException('Invalid browser session.');
  }
}

bool _optional<T>(Object? value) => value == null || value is T;

List<BrowserTab> _decodeBrowserTabs(List<Object?> tabs) => tabs.map((item) {
  if (item is! Map<String, dynamic>) {
    throw const FormatException('Invalid browser tab.');
  }

  return BrowserTab.fromJson(item);
}).toList();

List<WorkspaceContentTab> _decodeWorkspaceContentTabs(List<Object?> tabs) =>
    tabs.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid workspace content tab.');
      }

      return WorkspaceContentTab.fromJson(item);
    }).toList();

class const WorkspaceContentTab({
  required final String id,
  required final String kind,
}) {
  factory fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final kind = json['kind'];
    if (id is! String || kind is! String) {
      throw const FormatException('Invalid workspace content tab.');
    }

    return WorkspaceContentTab(id: id, kind: kind);
  }

  String get key => kind == 'directory' ? 'directory' : '$kind:$id';
  Map<String, Object?> toJson() => {'id': id, 'kind': kind};
}

class const BrowserTab({
  required final String id,
  required final String url,
  final String title = '',
}) {
  factory fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final url = json['url'];
    final title = json['title'];
    if (id is! String || url is! String || title != null && title is! String) {
      throw const FormatException('Invalid browser tab.');
    }

    return BrowserTab(id: id, url: url, title: title is String ? title : '');
  }

  BrowserTab copyWith({String? url, String? title}) =>
      BrowserTab(id: id, url: url ?? this.url, title: title ?? this.title);

  Map<String, Object?> toJson() => {'id': id, 'url': url, 'title': title};
}
