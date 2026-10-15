import 'package:auravibes_app/data/repositories/browser_session_repository.dart';
import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentToolExecutionOutput;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_browser_web_view_service.dart';

void main() {
  test('suspends browser views but preserves tabs for resume', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService();
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);

    await notifier.openTab(url: 'https://one.example');
    await notifier.openTab(url: 'https://two.example');
    final openSession = container.read(provider).requireValue;

    await notifier.suspend();

    final suspendedSession = container.read(provider).requireValue;
    expect(suspendedSession.isSuspended, isTrue);
    expect(
      suspendedSession.tabs.map((tab) => tab.toJson()).toList(),
      openSession.tabs.map((tab) => tab.toJson()).toList(),
    );
    expect(runtime.actions, ['remove', 'remove']);

    await notifier.resume();

    final resumedSession = container.read(provider).requireValue;
    expect(resumedSession.isSuspended, isFalse);
    expect(
      resumedSession.tabs.map((tab) => tab.toJson()).toList(),
      openSession.tabs.map((tab) => tab.toJson()).toList(),
    );

    final storedSession = await BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    ).load('conversation');
    expect(storedSession.isSuspended, isFalse);
    expect(
      storedSession.tabs.map((tab) => tab.toJson()).toList(),
      openSession.tabs.map((tab) => tab.toJson()).toList(),
    );
  });

  test('closes all browser tabs and clears suspended state', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService();
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab(url: 'https://one.example');
    await notifier.openTab(url: 'https://two.example');
    await notifier.suspend();

    await notifier.closeAllTabs();

    final session = container.read(provider).requireValue;
    expect(session.tabs, isEmpty);
    expect(session.activeTabId, isEmpty);
    expect(session.isSuspended, isFalse);
    expect(runtime.actions, ['remove', 'remove']);
  });

  test('keeps a session alive until its final browser tab closes', () async {
    SharedPreferences.setMockInitialValues({});
    final observer = _DisposedProviderObserver();
    final container = ProviderContainer(observers: [observer]);
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final emittedStates = <AsyncValue<BrowserSessionState>>[];
    final subscription = container.listen(provider, (_, next) {
      final _ = emittedStates.add(next);
    });
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();
    subscription.close();
    await container.pump();

    expect(emittedStates, isNotEmpty);
    expect(observer.disposedProviders, isNot(contains(provider.toString())));
    final tabs = await notifier.runSkillTool('browser_list_tabs', {});
    expect(tabs, hasLength(1));
    expect(container.read(provider).requireValue.agentActionRevision, 1);

    await notifier.closeTab(
      container.read(provider).requireValue.tabs.single.id,
    );
    await container.pump();

    expect(observer.disposedProviders, contains(provider.toString()));
  });

  test('opens a tab and keeps the previous tab selectable', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final emittedSessions = <BrowserSessionState>[];
    final subscription = container.listen(provider, (_, next) {
      if (next case AsyncData(:final value)) emittedSessions.add(value);
    });
    addTearDown(subscription.close);

    final initialSession = await container.read(provider.future);
    final notifier = container.read(provider.notifier);

    expect(initialSession.tabs, isEmpty);
    expect(initialSession.activeTabId, isEmpty);
    expect(initialSession.activeTab, isNull);

    await notifier.openTab();
    final previousSession = container.read(provider).requireValue;
    await notifier.openTab();

    final openedSession = container.read(provider).requireValue;
    expect(openedSession.tabs, hasLength(2));
    expect(openedSession.activeTabId, isNot(previousSession.activeTabId));
    expect(openedSession.agentActionRevision, 0);
    expect(openedSession.toJson(), isNot(contains('agentActionRevision')));

    await notifier.selectTab(previousSession.activeTabId);

    expect(
      container.read(provider).requireValue.activeTabId,
      previousSession.activeTabId,
    );
    expect(emittedSessions.any((session) => session.tabs.length == 2), isTrue);
    expect(
      emittedSessions.any(
        (session) => session.activeTabId == previousSession.activeTabId,
      ),
      isTrue,
    );

    final revision = container.read(provider).requireValue.agentActionRevision;
    final tabs = await notifier.runSkillTool('browser_list_tabs', {});
    expect(tabs, hasLength(2));
    expect(
      container.read(provider).requireValue.agentActionRevision,
      revision + 1,
    );

    await notifier.closeTab(openedSession.activeTabId);
    await notifier.closeTab(previousSession.activeTabId);

    expect(container.read(provider).requireValue.tabs, isEmpty);
    expect(container.read(provider).requireValue.activeTabId, isEmpty);
  });

  test('reads browser content as Markdown, HTML, and TOON', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()
      ..result = {
        'url': 'https://example.com',
        'title': 'Example',
        'html': '<main><h1>Heading</h1><p>Visible text</p></main>',
      };
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    final markdown = await notifier.runSkillTool('browser_read_page', {
      'format': 'markdown',
    });
    final text = await notifier.runSkillTool('browser_read_page', {
      'format': 'text',
    });
    final html = await notifier.runSkillTool('browser_read_page', {
      'format': 'html',
    });
    final toon = await notifier.runSkillTool('browser_read_page', {
      'format': 'toon',
    });

    if (markdown is! Map<Object?, Object?> || html is! Map<Object?, Object?>) {
      fail('Browser page output must be a structured map.');
    }
    expect(markdown['content'], contains('# Heading'));
    expect(markdown['content'], contains('Visible text'));
    expect(text, isA<Map<Object?, Object?>>());
    expect(html['content'], contains('<main>'));
    expect(toon, contains('https://example.com'));
    expect(runtime.lastSource, contains('input[type="hidden"]'));
  });

  test('queries bounded page fragments by CSS selector', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()
      ..result = {
        'url': 'https://example.com',
        'title': 'Example',
        'count': 2,
        'matches': [
          {'html': '<article><p>First fragment</p></article>'},
          {'html': '<article><p>Second fragment</p></article>'},
        ],
      };
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    final result = await notifier.runSkillTool('browser_query_page', {
      'selector': 'article',
      'format': 'text',
      'limit': 2,
    });
    if (result is! Map<Object?, Object?>) {
      fail('Browser query output must be a structured map.');
    }

    expect(result['count'], 2);
    expect(result['matches'], ['First fragment', 'Second fragment']);
    expect(runtime.lastSource, contains('querySelectorAll(selector)'));
  });

  test('executes JavaScript and bounds large structured results', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()
      ..result = {'value': List.filled(20000, 'x').join()};
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    final result = await notifier.runSkillTool('browser_execute_javascript', {
      'source': '1 + 1',
    });

    expect(result, isA<Map<Object?, Object?>>());
    if (result is! Map<Object?, Object?>) {
      fail('Large JavaScript result must include truncation metadata.');
    }
    expect(result['truncated'], isTrue);
    expect(result['preview'], isA<String>());
    expect(runtime.lastSource, '1 + 1');
  });

  test('clicks and fills one page element through JavaScript', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()..result = {'clicked': true};
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    final clicked = await notifier.runSkillTool('browser_click', {
      'selector': 'button.save',
    });
    runtime.nextResult = {'filled': true};
    final filled = await notifier.runSkillTool('browser_fill', {
      'selector': 'input[name="query"]',
      'text': 'search text',
    });

    expect(clicked, {'clicked': true});
    expect(filled, {'filled': true});
    expect(filled.toString(), isNot(contains('search text')));
    expect(runtime.lastSource, contains(r'input[name=\"query\"]'));
    expect(runtime.lastSource, contains('HTMLTextAreaElement'));
    expect(runtime.lastSource, contains('Password fields cannot be filled.'));
  });

  test('surfaces browser element action errors', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()
      ..result = {'error': 'Selector must match exactly one element.'};
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    await expectLater(
      notifier.runSkillTool('browser_click', {'selector': 'button'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Selector must match exactly one element.',
        ),
      ),
    );
  });

  test(
    'rejects oversized browser interaction inputs before execution',
    () async {
      SharedPreferences.setMockInitialValues({});
      final runtime = FakeBrowserWebViewService();
      final container = ProviderContainer(
        overrides: [
          browserWebViewServiceProvider.overrideWithValue(runtime.service),
        ],
      );
      addTearDown(container.dispose);
      final provider = browserSessionProvider('workspace', 'conversation');
      final _ = await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      await notifier.openTab();

      await expectLater(
        notifier.runSkillTool('browser_click', {'selector': 'x' * 257}),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        notifier.runSkillTool('browser_fill', {
          'selector': 'input',
          'text': 'x' * 16001,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(runtime.lastSource, isNull);
    },
  );

  test('rejects unsupported browser tool URLs without opening a tab', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    final initialTabCount = container.read(provider).requireValue.tabs.length;
    expect(initialTabCount, 0);

    await expectLater(
      notifier.runSkillTool('browser_open_tab', {'url': 'file:///etc/passwd'}),
      throwsA(isA<FormatException>()),
    );

    expect(
      container.read(provider).requireValue.tabs,
      hasLength(initialTabCount),
    );
  });

  test('requires an open tab before reading browser content', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService();
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);

    await expectLater(
      notifier.runSkillTool('browser_read_page', {}),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Open a browser tab first.',
        ),
      ),
    );

    expect(runtime.lastSource, isNull);
    expect(container.read(provider).requireValue.tabs, isEmpty);
  });

  test('dispatches back, forward, and reload to selected tab', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService();
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();
    final tabId = container.read(provider).requireValue.activeTabId;

    final back = await notifier.runSkillTool('browser_go_back', {
      'tabId': tabId,
    });
    final forward = await notifier.runSkillTool('browser_go_forward', {
      'tabId': tabId,
    });
    final _ = await notifier.runSkillTool('browser_reload', {'tabId': tabId});

    expect(back, {'changed': true, 'tabId': tabId});
    expect(forward, {'changed': true, 'tabId': tabId});
    expect(runtime.actions, ['back', 'forward', 'reload']);
  });

  test(
    'snapshot exposes bounded semantic fields without form values',
    () async {
      SharedPreferences.setMockInitialValues({});
      final elements = [
        for (var index = 0; index < 30; index++)
          {
            'ref': 'snapshot:$index',
            'role': 'button',
            'name': 'Save $index',
            'text': 'Save',
            'tag': 'button',
          },
      ];
      final runtime = FakeBrowserWebViewService()
        ..result = {
          'url': 'https://example.com',
          'title': 'Example',
          'count': 31,
          'truncated': true,
          'elements': elements,
        };
      final container = ProviderContainer(
        overrides: [
          browserWebViewServiceProvider.overrideWithValue(runtime.service),
        ],
      );
      addTearDown(container.dispose);
      final provider = browserSessionProvider('workspace', 'conversation');
      final _ = await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      await notifier.openTab();

      final snapshot = await notifier.runSkillTool('browser_snapshot', {});

      expect(snapshot, isA<Map<Object?, Object?>>());
      expect(snapshot.toString(), isNot(contains('password-value')));
      expect(snapshot.toString(), isNot(contains('input-value')));
      expect(
        runtime.lastSource,
        contains('input:not([type="hidden"]):not([type="password"])'),
      );
      expect(runtime.lastSource, contains('elements.length >= 30'));
      expect(runtime.lastSource, isNot(contains('element.value')));
    },
  );

  test('find matches semantic role, name, and text', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()
      ..result = {
        'url': 'https://example.com',
        'title': 'Example',
        'count': 2,
        'truncated': false,
        'elements': [
          {'ref': 'r1', 'role': 'button', 'name': 'Save draft', 'text': 'Save'},
          {'ref': 'r2', 'role': 'link', 'name': 'Save draft', 'text': 'Save'},
        ],
      };
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    final result = await notifier.runSkillTool('browser_find', {
      'role': 'button',
      'name': 'save',
      'text': 'save',
    });

    if (result is! Map<Object?, Object?>) {
      fail('Browser find output must be a structured map.');
    }
    expect(result['count'], 1);
    final matches = result['matches'];
    if (matches is! List<Object?>) {
      fail('Browser find matches must be a list.');
    }
    final firstMatch = matches.single;
    if (firstMatch is! Map<Object?, Object?>) {
      fail('Browser find match must be a map.');
    }
    expect(firstMatch['ref'], 'r1');
  });

  test('wait handles delayed matches and bounded timeouts', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()
      ..scriptedResults.addAll([
        {'found': false},
        {'found': true},
        {
          'url': 'https://example.com',
          'title': 'Example',
          'count': 1,
          'truncated': false,
          'elements': [
            {
              'ref': 'r1',
              'role': 'button',
              'name': 'Continue',
              'text': 'Continue',
            },
          ],
        },
      ]);
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    var observedUpdates = 0;
    final subscription = container.listen(
      provider,
      (_, _) => observedUpdates++,
    );
    addTearDown(subscription.close);
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    final delayed = await notifier.runSkillTool('browser_wait_for', {
      'selector': 'button.continue',
      'timeoutMs': 300,
    });
    runtime.result = {
      'url': 'https://example.com',
      'title': 'Example',
      'count': 0,
      'truncated': false,
      'elements': <Object?>[],
    };
    final timedOut = await notifier.runSkillTool('browser_wait_for', {
      'text': 'never appears',
      'timeoutMs': 1,
    });

    expect(delayed, isA<Map<Object?, Object?>>());
    expect(timedOut, {'found': false, 'timeoutMs': 1});
    expect(observedUpdates, greaterThan(0));
  });

  test('snapshot refs work until navigation invalidates them', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService()
      ..result = {
        'url': 'https://example.com',
        'title': 'Example',
        'count': 1,
        'truncated': false,
        'elements': [
          {'ref': 'ignored', 'role': 'button', 'name': 'Save', 'text': 'Save'},
        ],
      };
    final container = ProviderContainer(
      overrides: [
        browserWebViewServiceProvider.overrideWithValue(runtime.service),
      ],
    );
    addTearDown(container.dispose);
    final provider = browserSessionProvider('workspace', 'conversation');
    final _ = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    await notifier.openTab();

    final _ = await notifier.runSkillTool('browser_snapshot', {});
    final source = runtime.lastSource;
    if (source == null) fail('Expected snapshot script.');
    final snapshotId = RegExp('const id = "([^"]+)";')
        .firstMatch(source)
        ?.group(1);
    if (snapshotId == null) fail('Expected snapshot ID.');
    final ref = '$snapshotId:1';
    final clicked = await notifier.runSkillTool('browser_click', {'ref': ref});
    final _ = await notifier.runSkillTool('browser_navigate', {
      'url': 'https://example.com/next',
    });

    await expectLater(
      notifier.runSkillTool('browser_click', {'ref': ref}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Browser element ref is stale. Take a fresh snapshot.',
        ),
      ),
    );
    expect(clicked, isA<Map<Object?, Object?>>());
  });

  test(
    'selects options, checks controls, scrolls, and captures screenshot',
    () async {
      SharedPreferences.setMockInitialValues({});
      final runtime = FakeBrowserWebViewService()
        ..result = {
          'url': 'https://example.com',
          'title': 'Example',
          'count': 0,
          'truncated': false,
          'elements': <Object?>[],
        }
        ..nextResult = {'x': 0, 'y': 500}
        ..screenshotBytes = .fromList([137, 80, 78, 71]);
      final container = ProviderContainer(
        overrides: [
          browserWebViewServiceProvider.overrideWithValue(runtime.service),
        ],
      );
      addTearDown(container.dispose);
      final provider = browserSessionProvider('workspace', 'conversation');
      final _ = await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      await notifier.openTab();

      final _ = await notifier.runSkillTool('browser_select_option', {
        'selector': 'select[name="region"]',
        'value': 'us',
      });
      expect(runtime.lastSource, contains('selected: true'));
      final _ = await notifier.runSkillTool('browser_set_checked', {
        'selector': 'input[name="terms"]',
        'checked': true,
      });
      expect(runtime.lastSource, contains('const checked = true'));
      final scrolled = await notifier.runSkillTool('browser_scroll', {
        'y': 500,
      });
      expect(scrolled, {'scrolled': true, 'x': 0, 'y': 500});
      expect(runtime.actions, contains('scroll:0:500'));
      final screenshot = await notifier.runSkillTool(
        'browser_capture_screenshot',
        {},
      );

      expect(screenshot, isA<AgentToolExecutionOutput>());
      if (screenshot is! AgentToolExecutionOutput) {
        fail('Browser screenshot output must contain typed media.');
      }
      expect(screenshot.media.single.mimeType, 'image/png');
    },
  );
}

final class _DisposedProviderObserver extends ProviderObserver {
  final disposedProviders = <String>[];

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposedProviders.add(context.provider.toString());
  }
}
