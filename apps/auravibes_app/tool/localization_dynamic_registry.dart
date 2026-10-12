/// A reviewed finite translation family and the source sites that may use it.
class LocalizationDynamicRegistry {
  const new({
    required this.family,
    required this.sites,
    this.keys = const {},
    this.keyPrefixes = const {},
  });

  final String family;
  final List<DynamicTranslationSite> sites;

  /// Exact keys allowed for this family.
  final Set<String> keys;

  /// Catalog namespaces that represent a finite, intentionally dynamic family.
  /// Every catalog key under each prefix is checked in every supported locale.
  final Set<String> keyPrefixes;
}

/// One dynamic translation call site included in a registered key family.
class DynamicTranslationSite {
  const new({
    required this.file,
    required this.line,
    required this.method,
    required this.keyExpression,
  });

  final String file;
  final int line;
  final String method;
  final String keyExpression;
}

/// Dynamic translations are listed by source call site and finite key family.
const localizationDynamicKeyRegistry = <LocalizationDynamicRegistry>[
  LocalizationDynamicRegistry(
    family: 'agent-form-validation-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/agents/screens/agent_detail_screen.dart',
        line: 1222,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
      DynamicTranslationSite(
        file: 'features/agents/screens/agent_detail_screen.dart',
        line: 1289,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
      DynamicTranslationSite(
        file: 'features/agents/screens/agent_detail_screen.dart',
        line: 1322,
        method: 'tr',
        keyExpression: 'errorKey',
      ),
    ],
    keyPrefixes: {'agents.'},
  ),

  LocalizationDynamicRegistry(
    family: 'app-skill-title-and-description-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/agents/screens/agent_detail_screen.dart',
        line: 2889,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skills_screen.dart',
        line: 741,
        method: 'tr',
        keyExpression: 'skill.titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skills_screen.dart',
        line: 1424,
        method: 'tr',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skills_screen.dart',
        line: 1663,
        method: 'tr',
        keyExpression: 'descriptionKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skills_screen.dart',
        line: 1679,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
    ],
    keyPrefixes: {'app_skills.'},
  ),

  LocalizationDynamicRegistry(
    family: 'chat-screen-model-and-activity-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/screens/chat_conversation_screen.dart',
        line: 1431,
        method: 'TextLocale',
        keyExpression: 'hint',
      ),
      DynamicTranslationSite(
        file: 'features/chats/screens/chat_conversation_screen.dart',
        line: 2516,
        method: 'tr',
        keyExpression: 'localeKey',
      ),
      DynamicTranslationSite(
        file: 'features/chats/screens/chat_conversation_screen.dart',
        line: 2763,
        method: 'tr',
        // Store the exact source form the scanner reports for this call site.
        // ignore: avoid_escaping_inner_quotes
        keyExpression: '\'conversation_activity.\$activityKey\'',
      ),
    ],
    keyPrefixes: {
      'chats_screens.chat_conversation.',
      'compaction.',
      'conversation_activity.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'chat-a2ui-copy-and-action-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_a2ui_warning.dart',
        line: 132,
        method: 'tr',
        keyExpression: 'key',
      ),
    ],
    keys: {
      'chats_screens.chat_conversation.a2ui_diagnostic_copied',
      'chats_screens.chat_conversation.a2ui_form_invalid',
      'chats_screens.chat_conversation.a2ui_unavailable',
      'chats_screens.chat_conversation.copy_a2ui_diagnostic',
      'chats_screens.chat_conversation.form_submitted',
      'chats_screens.chat_conversation.submit_answers',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'chat-input-attachment-and-hint-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_input_widget.dart',
        line: 797,
        method: 'TextLocale',
        keyExpression: 'localizationKey',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_input_widget.dart',
        line: 1306,
        method: 'TextLocale',
        keyExpression: 'request.titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_input_widget.dart',
        line: 1320,
        method: 'tr',
        keyExpression: 'messageKey',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_input_widget.dart',
        line: 1503,
        method: 'tr',
        keyExpression: 'localeKey',
      ),
    ],
    keyPrefixes: {'chats_screens.chat_conversation.', 'compaction.'},
  ),

  LocalizationDynamicRegistry(
    family: 'chat-list-error-and-bulk-action-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_list_widget.dart',
        line: 805,
        method: 'TextLocale',
        keyExpression: '_chatDeleteErrorKey(error)',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_list_widget.dart',
        line: 1105,
        method: 'TextLocale',
        keyExpression: 'key',
      ),
    ],
    keyPrefixes: {
      'chats_screens.chat_conversation.',
      'chats_screens.chats_list.bulk_',
      'cloud_errors.',
      'workspace_capabilities.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'chat-relative-time-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_messages_widget.dart',
        line: 1324,
        method: 'tr',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'utils/relative_time_formatter.dart',
        line: 51,
        method: 'tr',
        keyExpression: 'key',
      ),
    ],
    keys: {
      'home_screen.date_formatting.days_ago',
      'home_screen.date_formatting.hours_ago',
      'home_screen.date_formatting.just_now',
      'home_screen.date_formatting.minutes_ago',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'chat-timeline-tool-status-and-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_messages_widget.dart',
        line: 2440,
        method: 'tr',
        keyExpression: 'statusKey',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_messages_widget.dart',
        line: 2492,
        method: 'tr',
        keyExpression: 'statusKey',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_messages_widget.dart',
        line: 2646,
        method: 'tr',
        keyExpression: 'truncationKey',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_messages_widget.dart',
        line: 2692,
        method: 'TextLocale',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_messages_widget.dart',
        line: 2875,
        method: 'tr',
        keyExpression: 'content',
      ),
    ],
    keyPrefixes: {
      'chats_screens.chat_conversation.',
      'cloud_errors.',
      'tool_call_status.',
      'workspace_capabilities.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'chat-tool-approval-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/chat_tool_approval_card.dart',
        line: 73,
        method: 'TextLocale',
        keyExpression:
            'error is CloudAppException ? '
            'CloudAppErrors.localizationKey(error) : '
            'request.errorMessageKey',
      ),
    ],
    keyPrefixes: {
      'cloud_errors.',
      'tool_approval.errors.',
      'workspace_capabilities.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'chat-compaction-history-error-keys',
    sites: [
      DynamicTranslationSite(
        file:
            'features/chats/widgets/compaction_checkpoint_history_dialog.dart',
        line: 38,
        method: 'TextLocale',
        keyExpression: 'error',
      ),
    ],
    keyPrefixes: {'compaction.'},
  ),

  LocalizationDynamicRegistry(
    family: 'conversation-archive-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/conversation_archive_feedback.dart',
        line: 20,
        method: 'TextLocale',
        keyExpression: 'localizationKey',
      ),
    ],
    keyPrefixes: {'chats_screens.chat_conversation.archive_'},
  ),

  LocalizationDynamicRegistry(
    family: 'chat-sidebar-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/sidebar_conversations_widget.dart',
        line: 195,
        method: 'TextLocale',
        keyExpression: 'CloudAppErrors.localizationKey(error)',
      ),
      DynamicTranslationSite(
        file: 'features/chats/widgets/sidebar_conversations_widget.dart',
        line: 537,
        method: 'TextLocale',
        keyExpression: '_deleteErrorKey(error)',
      ),
    ],
    keys: {'chats_screens.chat_conversation.delete_error'},
    keyPrefixes: {'cloud_errors.', 'workspace_capabilities.'},
  ),

  LocalizationDynamicRegistry(
    family: 'skill-tool-call-title-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/chats/widgets/skill_tool_call_display.dart',
        line: 80,
        method: 'tr',
        keyExpression: 'titleKey',
      ),
    ],
    keyPrefixes: {'skills_tool.', 'tools_names.'},
  ),

  LocalizationDynamicRegistry(
    family: 'cloud-account-ui-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/cloud_accounts/screens/cloud_accounts_screen.dart',
        line: 150,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/screens/cloud_accounts_screen.dart',
        line: 155,
        method: 'tr',
        keyExpression: 'messageKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/screens/cloud_accounts_screen.dart',
        line: 163,
        method: 'TextLocale',
        keyExpression: 'actionKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/screens/cloud_accounts_screen.dart',
        line: 216,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/widgets/cloud_account_auth_content.dart',
        line: 210,
        method: 'TextLocale',
        keyExpression: 'data.presentation.title',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/widgets/cloud_account_auth_content.dart',
        line: 469,
        method: 'TextLocale',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart',
        line: 124,
        method: 'TextLocale',
        keyExpression: 'statusKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart',
        line: 126,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/widgets/cloud_account_login_form.dart',
        line: 89,
        method: 'TextLocale',
        keyExpression: 'statusKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_accounts/widgets/cloud_account_login_form.dart',
        line: 91,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
      DynamicTranslationSite(
        file:
            'features/cloud_accounts/widgets/cloud_account_register_form.dart',
        line: 126,
        method: 'TextLocale',
        keyExpression: 'statusKey',
      ),
      DynamicTranslationSite(
        file:
            'features/cloud_accounts/widgets/cloud_account_register_form.dart',
        line: 128,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
    ],
    keyPrefixes: {'cloud_accounts.'},
  ),

  LocalizationDynamicRegistry(
    family: 'cloud-workspace-error-and-action-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart',
        line: 134,
        method: 'TextLocale',
        keyExpression:
            'switch (state) { AsyncError(:final error) => '
            '_cloudErrorKey(error), _ => '
            'LocaleKeys.cloud_errors_unavailable, }',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart',
        line: 171,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart',
        line: 440,
        method: 'TextLocale',
        keyExpression: '_cloudErrorKey(error)',
      ),
      DynamicTranslationSite(
        file: 'features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart',
        line: 670,
        method: 'tr',
        keyExpression: 'key',
      ),
    ],
    keyPrefixes: {
      'cloud_errors.',
      'cloud_workspaces.',
      'workspace_capabilities.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'markdown-editor-label-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/markdown/screens/markdown_editor_screen.dart',
        line: 197,
        method: 'TextLocale',
        keyExpression: 'draftHintKey',
      ),
      DynamicTranslationSite(
        file: 'features/markdown/screens/markdown_editor_screen.dart',
        line: 543,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/markdown/widgets/empty_markdown_preview.dart',
        line: 14,
        method: 'TextLocale',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/markdown/widgets/markdown_editor_toolbar.dart',
        line: 916,
        method: 'tr',
        keyExpression: 'action.labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/markdown/widgets/markdown_preview_field.dart',
        line: 79,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/markdown/widgets/markdown_preview_field.dart',
        line: 99,
        method: 'TextLocale',
        keyExpression: 'editKey',
      ),
    ],
    keyPrefixes: {'markdown_editor.'},
  ),

  LocalizationDynamicRegistry(
    family: 'model-provider-form-label-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/models/widgets/add_model_provider_widget.dart',
        line: 1259,
        method: 'TextLocale',
        keyExpression: 'title',
      ),
      DynamicTranslationSite(
        file: 'features/models/widgets/add_model_provider_widget.dart',
        line: 1698,
        method: 'TextLocale',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/models/widgets/add_model_provider_widget.dart',
        line: 2062,
        method: 'TextLocale',
        keyExpression: 'localeKey',
      ),
      DynamicTranslationSite(
        file: 'features/models/widgets/enhanced_model_input.dart',
        line: 141,
        method: 'TextLocale',
        keyExpression: 'fieldData.placeholder',
      ),
      DynamicTranslationSite(
        file: 'features/models/widgets/enhanced_model_input.dart',
        line: 142,
        method: 'TextLocale',
        keyExpression: 'fieldData.label',
      ),
      DynamicTranslationSite(
        file: 'features/models/widgets/enhanced_model_input.dart',
        line: 144,
        method: 'TextLocale',
        keyExpression: 'hint',
      ),
    ],
    keyPrefixes: {'models_screens.'},
  ),

  LocalizationDynamicRegistry(
    family: 'service-connection-and-mcp-label-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connection_create_screen.dart',
        line: 1079,
        method: 'tr',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connection_edit_screen.dart',
        line: 930,
        method: 'TextLocale',
        keyExpression: 'localeKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connection_edit_screen.dart',
        line: 1493,
        method: 'tr',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connection_edit_screen.dart',
        line: 1549,
        method: 'TextLocale',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connection_edit_screen.dart',
        line: 2167,
        method: 'tr',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 444,
        method: 'TextLocale',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 695,
        method: 'TextLocale',
        keyExpression: 'option.titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 912,
        method: 'TextLocale',
        keyExpression: 'option.titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 1127,
        method: 'tr',
        keyExpression: 'localeKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 1438,
        method: 'TextLocale',
        keyExpression: 'guidanceKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 1620,
        method: 'tr',
        keyExpression: 'warning.titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 1645,
        method: 'TextLocale',
        keyExpression: 'action.labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 1984,
        method: 'tr',
        keyExpression: 'messageKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 1995,
        method: 'TextLocale',
        keyExpression: 'keys.titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 2189,
        method: 'TextLocale',
        keyExpression: 'messageKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 2298,
        method: 'tr',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/screens/service_connections_screen.dart',
        line: 2312,
        method: 'tr',
        keyExpression: 'localeKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/widgets/connections_tabs.dart',
        line: 53,
        method: 'TextLocale',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/widgets/connections_tabs.dart',
        line: 54,
        method: 'tr',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/widgets/mcp_catalog_browser.dart',
        line: 518,
        method: 'tr',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/service_connections/widgets/mcp_catalog_browser.dart',
        line: 743,
        method: 'tr',
        keyExpression: 'key',
      ),
    ],
    keyPrefixes: {
      'connection_setup.',
      'mcp_catalog.',
      'mcp_edit.',
      'mcp_modal.',
      'service_connections.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'settings-and-compaction-label-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/settings/screens/more_screen.dart',
        line: 194,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/settings/screens/more_screen.dart',
        line: 195,
        method: 'TextLocale',
        keyExpression: 'subtitleKey',
      ),
      DynamicTranslationSite(
        file: 'features/settings/widgets/compaction_settings_section.dart',
        line: 420,
        method: 'tr',
        keyExpression: 'localeKey',
      ),
      DynamicTranslationSite(
        file: 'features/settings/widgets/compaction_settings_section.dart',
        line: 487,
        method: 'TextLocale',
        keyExpression: 'localeKey',
      ),
      DynamicTranslationSite(
        file: 'features/settings/widgets/compaction_settings_section.dart',
        line: 689,
        method: 'tr',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/settings/widgets/legal_links_section.dart',
        line: 40,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
    ],
    keyPrefixes: {'compaction.', 'more_screen.', 'settings_screen.'},
  ),

  LocalizationDynamicRegistry(
    family: 'skill-credential-definition-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_credential_definition_edit_screen.dart',
        line: 491,
        method: 'tr',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_credential_definition_edit_screen.dart',
        line: 507,
        method: 'tr',
        keyExpression: 'conflict.localizationKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_credential_definition_edit_screen.dart',
        line: 1227,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_credential_definition_edit_screen.dart',
        line: 1270,
        method: 'tr',
        keyExpression: 'tooltipKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_credential_definition_edit_screen.dart',
        line: 1322,
        method: 'TextLocale',
        keyExpression: 'labelKey',
      ),
    ],
    keyPrefixes: {
      'common.',
      'skill_credentials.',
      'skill_credentials_definitions.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'skill-authoring-and-selector-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_detail_screen.dart',
        line: 267,
        method: 'tr',
        keyExpression: 'key',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_detail_screen.dart',
        line: 1816,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_detail_screen.dart',
        line: 1830,
        method: 'TextLocale',
        keyExpression: 'descriptionKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_detail_screen.dart',
        line: 2320,
        method: 'TextLocale',
        keyExpression: 'hintKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_detail_screen.dart',
        line: 2334,
        method: 'TextLocale',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_resource_edit_screen.dart',
        line: 252,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_tool_edit_screen.dart',
        line: 2098,
        method: 'TextLocale',
        keyExpression: 'sectionTitleKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_tool_edit_screen.dart',
        line: 2099,
        method: 'TextLocale',
        keyExpression: 'hintKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_tool_edit_screen.dart',
        line: 2116,
        method: 'tr',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_tool_edit_screen.dart',
        line: 2132,
        method: 'tr',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_tool_edit_screen.dart',
        line: 2145,
        method: 'tr',
        keyExpression: 'placeholderKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_tool_edit_screen.dart',
        line: 2146,
        method: 'tr',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skill_tool_edit_screen.dart',
        line: 2582,
        method: 'TextLocale',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/screens/skills_screen.dart',
        line: 1211,
        method: 'TextLocale',
        keyExpression: 'labelKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/widgets/conversation_skill_selector_modal.dart',
        line: 559,
        method: 'TextLocale',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/widgets/conversation_skill_selector_modal.dart',
        line: 561,
        method: 'TextLocale',
        keyExpression: 'emptyKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/widgets/conversation_skill_selector_modal.dart',
        line: 695,
        method: 'TextLocale',
        keyExpression: 'resultKey',
      ),
      DynamicTranslationSite(
        file: 'features/skills/widgets/conversation_skill_selector_modal.dart',
        line: 859,
        method: 'TextLocale',
        keyExpression: 'textKey',
      ),
    ],
    keyPrefixes: {
      'cloud_errors.',
      'skill_access.',
      'skill_credentials_definitions.',
      'skills_resource.',
      'skills_screen.',
      'skills_selector.',
      'skills_tool.',
      'workspace_capabilities.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'cloud-application-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/skills/screens/skills_screen.dart',
        line: 463,
        method: 'TextLocale',
        keyExpression: 'CloudAppErrors.localizationKey(error)',
      ),
    ],
    keyPrefixes: {'cloud_errors.', 'workspace_capabilities.'},
  ),

  LocalizationDynamicRegistry(
    family: 'tool-localized-display-name-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/tools/widgets/conversation_group_header.dart',
        line: 104,
        method: 'tr',
        keyExpression: 'groupWithTools.localizedDisplayNameKey',
      ),
      DynamicTranslationSite(
        file: 'features/tools/widgets/tools_group_header.dart',
        line: 160,
        method: 'tr',
        keyExpression: 'groupWithTools.localizedDisplayNameKey',
      ),
      DynamicTranslationSite(
        file: 'features/tools/widgets/tools_group_header.dart',
        line: 212,
        method: 'tr',
        keyExpression: 'groupWithTools.localizedDisplayNameKey',
      ),
      DynamicTranslationSite(
        file: 'features/tools/widgets/tools_management_modal.dart',
        line: 443,
        method: 'tr',
        keyExpression: 'group.localizedDisplayNameKey',
      ),
      DynamicTranslationSite(
        file: 'features/tools/widgets/tools_workspace_list_widget.dart',
        line: 801,
        method: 'tr',
        keyExpression: 'group.localizedDisplayNameKey',
      ),
      DynamicTranslationSite(
        file: 'features/tools/widgets/tools_workspace_list_widget.dart',
        line: 1071,
        method: 'tr',
        keyExpression: 'group.localizedDisplayNameKey',
      ),
    ],
    keyPrefixes: {'tools_names.'},
  ),

  LocalizationDynamicRegistry(
    family: 'tool-error-label-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/tools/widgets/add_mcp_modal.dart',
        line: 427,
        method: 'tr',
        keyExpression: 'errorMessage',
      ),
      DynamicTranslationSite(
        file: 'features/tools/widgets/tools_management_modal.dart',
        line: 325,
        method: 'TextLocale',
        keyExpression: 'CloudAppErrors.localizationKey(error)',
      ),
    ],
    keys: {
      'mcp_modal.oauth.cancelled',
      'mcp_modal.oauth.client_id_required',
      'mcp_modal.oauth.configuration',
      'mcp_modal.oauth.discovery',
      'mcp_modal.oauth.expired',
      'mcp_modal.oauth.issuer_mismatch',
      'mcp_modal.oauth.malformed',
      'mcp_modal.oauth.registration_failed',
      'mcp_modal.oauth.token_exchange',
      'mcp_modal.verification_expired',
      'mcp_modal.verification_required',
      'tools_screen.mcp_error',
      'workspace_capabilities.unsupported_error',
    },
    keyPrefixes: {'cloud_errors.', 'workspace_capabilities.'},
  ),

  LocalizationDynamicRegistry(
    family: 'workspace-creation-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/workspaces/screens/create_workspace_form.dart',
        line: 288,
        method: 'tr',
        keyExpression: 'error.localizationKey',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/create_workspace_form.dart',
        line: 349,
        method: 'tr',
        keyExpression: 'key',
      ),
    ],
    keyPrefixes: {
      'cloud_errors.',
      'workspace_capabilities.',
      'workspace_management.',
      'workspace_setup.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'workspace-management-and-archive-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 329,
        method: 'TextLocale',
        keyExpression: 'plan.title',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 336,
        method: 'TextLocale',
        keyExpression: 'plan.action',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 419,
        method: 'tr',
        keyExpression: 'titleKey',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 1524,
        method: 'TextLocale',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 1526,
        method: 'tr',
        keyExpression: 'label',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 1620,
        method: 'TextLocale',
        keyExpression: 'localizationKey',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 2966,
        method: 'TextLocale',
        keyExpression: 'keyName',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 3191,
        method: 'tr',
        keyExpression: 'localizationKey',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 3193,
        method: 'tr',
        keyExpression: 'localizationKey',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 3194,
        method: 'tr',
        keyExpression: 'localizationKey',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 3196,
        method: 'tr',
        keyExpression:
            '(fallbackKey ?? LocaleKeys.workspace_management_unexpected_error)',
      ),
      DynamicTranslationSite(
        file: 'features/workspaces/screens/workspace_management_screen.dart',
        line: 3210,
        method: 'tr',
        keyExpression: 'translated.localizationKey',
      ),
    ],
    keyPrefixes: {
      'cloud_errors.',
      'cloud_workspaces.',
      'workspace_archive.',
      'workspace_capabilities.',
      'workspace_management.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'workspace-selector-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/workspaces/widgets/workspace_selector.dart',
        line: 114,
        method: 'TextLocale',
        keyExpression: 'errorKey',
      ),
    ],
    keyPrefixes: {
      'cloud_errors.',
      'cloud_workspaces.',
      'workspace_capabilities.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'workspace-setup-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'features/workspaces/widgets/workspace_setup_content.dart',
        line: 312,
        method: 'TextLocale',
        keyExpression: 'message',
      ),
    ],
    keyPrefixes: {
      'cloud_errors.',
      'workspace_capabilities.',
      'workspace_setup.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'route-title-keys',
    sites: [
      DynamicTranslationSite(
        file: 'main.dart',
        line: 394,
        method: 'tr',
        keyExpression: 'key',
      ),
    ],
    keys: {
      'agents.title',
      'cloud_accounts.forgot_password',
      'cloud_accounts.login_existing',
      'cloud_accounts.register',
      'cloud_accounts.title',
      'intro_flow.welcome.title',
      'menu.chats',
      'menu.new_chat',
      'models_screens.title',
      'more_screen.title',
      'service_connections.title',
      'settings_screen.title',
      'skill_credentials_definitions.title',
      'skills_screen.title',
      'tools_screen.title',
      'workspace_management.title',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'application-error-keys',
    sites: [
      DynamicTranslationSite(
        file: 'widgets/app_error_widget.dart',
        line: 87,
        method: 'tr',
        keyExpression: 'localeKey',
      ),
    ],
    keys: {'common.error_message'},
    keyPrefixes: {'cloud_errors.', 'workspace_capabilities.'},
  ),

  LocalizationDynamicRegistry(
    family: 'sidebar-navigation-label-keys',
    sites: [
      DynamicTranslationSite(
        file: 'widgets/aura_sidebar_wrapper.dart',
        line: 72,
        method: 'TextLocale',
        keyExpression: 'translationKey',
      ),
      DynamicTranslationSite(
        file: 'widgets/aura_sidebar_wrapper.dart',
        line: 74,
        method: 'tr',
        keyExpression: 'translationKey',
      ),
    ],
    keys: {
      'cloud_accounts.title',
      'navigation.agents_skills',
      'navigation.chats',
      'navigation.connections',
      'settings_screen.title',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'friendly-build-error-label-keys',
    sites: [
      DynamicTranslationSite(
        file: 'widgets/friendly_build_error_widget.dart',
        line: 206,
        method: 'tr',
        keyExpression: 'localeKey',
      ),
    ],
    keys: {'common.error_message', 'common.error_title'},
  ),

  LocalizationDynamicRegistry(
    family: 'management-list-feedback-keys',
    sites: [
      DynamicTranslationSite(
        file: 'widgets/management_list_feedback.dart',
        line: 37,
        method: 'tr',
        keyExpression: 'messageKey',
      ),
      DynamicTranslationSite(
        file: 'widgets/management_list_feedback.dart',
        line: 90,
        method: 'tr',
        keyExpression: 'messageKey',
      ),
      DynamicTranslationSite(
        file: 'widgets/management_list_feedback.dart',
        line: 115,
        method: 'plural',
        keyExpression: 'key',
      ),
    ],
    keys: {
      'skills_screen.bulk_delete_confirm',
      'tools_screen.bulk_delete_confirm',
    },
    keyPrefixes: {
      'skills_screen.bulk_delete_failures.',
      'tools_screen.bulk_delete_failures.',
      'workspace_management.bulk_delete_failures.',
    },
  ),

  LocalizationDynamicRegistry(
    family: 'route-recovery-error-and-action-keys',
    sites: [
      DynamicTranslationSite(
        file: 'widgets/route_recovery_view.dart',
        line: 111,
        method: 'TextLocale',
        keyExpression: 'messageKey',
      ),
      DynamicTranslationSite(
        file: 'widgets/route_recovery_view.dart',
        line: 149,
        method: 'TextLocale',
        keyExpression: 'labelKey',
      ),
    ],
    keyPrefixes: {'cloud_errors.', 'route_state.', 'workspace_capabilities.'},
  ),
];
