class const BrowserSessionState({
  required final List<BrowserTab> tabs,
  required final String activeTabId,
  final bool isLoading = false,
  final bool hasError = false,
  final bool canGoBack = false,
  final bool canGoForward = false,
  final bool isSuspended = false,
  final String? agentActivity,
  final int agentActionRevision = 0,
}) {
  factory initial() => const BrowserSessionState(tabs: [], activeTabId: '');

  factory fromJson(Map<String, dynamic> json) {
    final storedTabs = json['tabs'];
    final storedActiveTabId = json['activeTabId'];
    final storedIsSuspended = json['isSuspended'];
    if (storedTabs is! List ||
        storedActiveTabId != null && storedActiveTabId is! String ||
        storedIsSuspended != null && storedIsSuspended is! bool) {
      throw const FormatException('Invalid browser session.');
    }

    final tabs = storedTabs.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid browser tab.');
      }

      return BrowserTab.fromJson(item);
    }).toList();
    final fallbackTab = tabs.firstOrNull;
    if (fallbackTab == null) return BrowserSessionState.initial();

    final activeTab = tabs
        .where((tab) => tab.id == storedActiveTabId)
        .firstOrNull;

    return BrowserSessionState(
      tabs: tabs,
      activeTabId: activeTab?.id ?? fallbackTab.id,
      isSuspended: storedIsSuspended is bool && storedIsSuspended,
    );
  }

  BrowserTab? get activeTab =>
      tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  Map<String, Object?> toJson() => {
    'tabs': tabs.map((tab) => tab.toJson()).toList(),
    'activeTabId': activeTabId,
    'isSuspended': isSuspended,
  };

  BrowserSessionState copyWith({
    List<BrowserTab>? tabs,
    String? activeTabId,
    bool? isLoading,
    bool? hasError,
    bool? canGoBack,
    bool? canGoForward,
    bool? isSuspended,
    String? agentActivity,
    int? agentActionRevision,
    bool clearAgentActivity = false,
  }) => BrowserSessionState(
    tabs: tabs ?? this.tabs,
    activeTabId: activeTabId ?? this.activeTabId,
    isLoading: isLoading ?? this.isLoading,
    hasError: hasError ?? this.hasError,
    canGoBack: canGoBack ?? this.canGoBack,
    canGoForward: canGoForward ?? this.canGoForward,
    isSuspended: isSuspended ?? this.isSuspended,
    agentActivity: clearAgentActivity
        ? null
        : agentActivity ?? this.agentActivity,
    agentActionRevision: agentActionRevision ?? this.agentActionRevision,
  );
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
