// Required: Tests keep helper functions top-level.

import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/main.dart' as app_main;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAppFlavor', () {
    test('resolves flavor by name', () {
      expect(app_main.AppFlavorResolver.resolve('dev'), Flavor.dev);
      expect(app_main.AppFlavorResolver.resolve('prod'), Flavor.prod);
    });

    test('throws when flavor name is missing', () {
      expect(() => app_main.AppFlavorResolver.resolve(null), throwsStateError);
    });
  });

  group('titleKeyForPath', () {
    test('uses the intro title for the initial root location', () {
      expect(
        app_main.RouteTitles.titleKeyForPath('/'),
        LocaleKeys.intro_flow_welcome_title,
      );
    });

    test('uses the intro title outside a workspace', () {
      expect(
        app_main.RouteTitles.titleKeyForPath('/intro'),
        LocaleKeys.intro_flow_welcome_title,
      );
    });

    test('titles workspace chat routes', () {
      expect(
        app_main.RouteTitles.titleKeyForPath('/workspaces/ws-1/chat/new'),
        LocaleKeys.menu_new_chat,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath('/workspaces/ws-1/chats/chat-1'),
        LocaleKeys.menu_chats,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath('/workspaces/ws-1/settings'),
        LocaleKeys.settings_screen_title,
      );
    });

    test('titles the More screen and its feature routes', () {
      expect(
        app_main.RouteTitles.titleKeyForPath('/workspaces/ws-1/more'),
        LocaleKeys.more_screen_title,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath(
          '/workspaces/ws-1/more/manage-workspaces',
        ),
        LocaleKeys.workspace_management_title,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath(
          '/workspaces/ws-1/more/cloud-accounts/login',
        ),
        LocaleKeys.cloud_accounts_login_existing,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath('/workspaces/ws-1/more/tools'),
        LocaleKeys.tools_screen_title,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath('/workspaces/ws-1/more/models'),
        LocaleKeys.models_screens_title,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath(
          '/workspaces/ws-1/more/service-connections/1',
        ),
        LocaleKeys.service_connections_title,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath(
          '/workspaces/ws-1/more/skills/skill-1/tools/1',
        ),
        LocaleKeys.skills_screen_title,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath(
          '/workspaces/ws-1/more/skill-credential-definitions/1',
        ),
        LocaleKeys.skill_credentials_definitions_title,
      );
      expect(
        app_main.RouteTitles.titleKeyForPath(
          '/workspaces/ws-1/more/agents/agent-1',
        ),
        LocaleKeys.agents_title,
      );
    });

    test(
      'ignores query and fragment and uses the app title for unknown paths',
      () {
        expect(
          app_main.RouteTitles.titleKeyForPath(
            '/workspaces/ws-1/chats?filter=recent#top',
          ),
          LocaleKeys.menu_chats,
        );
        expect(app_main.RouteTitles.titleKeyForPath('/unknown'), isNull);
      },
    );
  });
}
