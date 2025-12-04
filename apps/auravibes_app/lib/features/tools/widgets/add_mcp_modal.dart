import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for adding new MCP (Model Context Protocol) servers to the workspace
class AddMcpModal extends HookConsumerWidget {
  const AddMcpModal({super.key});

  /// Shows the add MCP modal as a dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const AddMcpModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the form state
    final formState = ref.watch(mcpFormProvider);
    final formNotifier = ref.read(mcpFormProvider.notifier);

    // Memoized computed values - no delay, instant recalculation
    final availableAuthTypes = useMemoized(
      () => formState.availableAuthTypes,
      [formState.transport],
    );

    final showOAuthFields = useMemoized(
      () => formState.showOAuthFields,
      [formState.authenticationType],
    );

    final showBearerTokenField = useMemoized(
      () => formState.showBearerTokenField,
      [formState.authenticationType],
    );

    final showHttp2Toggle = useMemoized(
      () => formState.showHttp2Toggle,
      [formState.transport],
    );

    // Text controllers synced with provider state
    final nameController = useTextEditingController(text: formState.name);
    final descriptionController = useTextEditingController(
      text: formState.description,
    );
    final urlController = useTextEditingController(text: formState.url);
    final clientIdController = useTextEditingController(
      text: formState.clientId,
    );
    final tokenEndpointController = useTextEditingController(
      text: formState.tokenEndpoint,
    );
    final authEndpointController = useTextEditingController(
      text: formState.authorizationEndpoint,
    );
    final bearerTokenController = useTextEditingController(
      text: formState.bearerToken,
    );

    // Reset form when modal opens
    useEffect(
      () {
        // Reset form state when modal is first built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          formNotifier.reset();
        });
        return null;
      },
      const [],
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.xl),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 450,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            _buildHeader(context),

            // Error message
            if (formState.errorMessage != null)
              _buildErrorBanner(context, formState.errorMessage!),

            // Scrollable form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.auraTheme.spacing.md),
                child: AuraColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AuraSpacing.md,
                  children: [
                    // Name field (required)
                    AuraInput(
                      controller: nameController,
                      onChanged: formNotifier.setName,
                      label: const TextLocale(
                        LocaleKeys.mcp_modal_fields_name_label,
                      ),
                      placeholder: const TextLocale(
                        LocaleKeys.mcp_modal_fields_name_placeholder,
                      ),
                    ),

                    // Description field (optional)
                    AuraInput(
                      controller: descriptionController,
                      onChanged: formNotifier.setDescription,
                      label: const TextLocale(
                        LocaleKeys.mcp_modal_fields_description_label,
                      ),
                      placeholder: const TextLocale(
                        LocaleKeys.mcp_modal_fields_description_placeholder,
                      ),
                    ),

                    // URL field (required)
                    AuraInput(
                      controller: urlController,
                      onChanged: formNotifier.setUrl,
                      label: const TextLocale(
                        LocaleKeys.mcp_modal_fields_url_label,
                      ),
                      placeholder: const TextLocale(
                        LocaleKeys.mcp_modal_fields_url_placeholder,
                      ),
                      hint: const TextLocale(
                        LocaleKeys.mcp_modal_fields_url_hint,
                      ),
                    ),

                    // Transport selector
                    _TransportSelector(
                      value: formState.transport,
                      onChanged: formNotifier.setTransport,
                    ),

                    // HTTP/2 toggle (only for streamableHttp)
                    if (showHttp2Toggle)
                      _Http2Toggle(
                        value: formState.useHttp2,
                        onChanged: (value) =>
                            formNotifier.setUseHttp2(value: value),
                      ),

                    // Authentication selector
                    _AuthenticationSelector(
                      value: formState.authenticationType,
                      availableTypes: availableAuthTypes,
                      onChanged: formNotifier.setAuthenticationType,
                    ),

                    // OAuth fields
                    if (showOAuthFields)
                      _OAuthFields(
                        clientIdController: clientIdController,
                        tokenEndpointController: tokenEndpointController,
                        authEndpointController: authEndpointController,
                        onClientIdChanged: formNotifier.setClientId,
                        onTokenEndpointChanged: formNotifier.setTokenEndpoint,
                        onAuthEndpointChanged:
                            formNotifier.setAuthorizationEndpoint,
                      ),

                    // Bearer token field
                    if (showBearerTokenField)
                      _BearerTokenField(
                        controller: bearerTokenController,
                        onChanged: formNotifier.setBearerToken,
                      ),
                  ],
                ),
              ),
            ),

            // Footer with action buttons
            _buildFooter(
              context,
              isLoading: formState.isSubmitting,
              onCancel: () => Navigator.of(context).pop(),
              onSave: () => _handleSave(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.spacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.auraColors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          AuraIcon(
            Icons.extension,
            color: context.auraColors.primary,
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          const Expanded(
            child: AuraText(
              style: AuraTextStyle.heading6,
              child: TextLocale(LocaleKeys.mcp_modal_title),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const AuraIcon(Icons.close),
            style: IconButton.styleFrom(
              foregroundColor: context.auraColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.md,
        vertical: context.auraTheme.spacing.sm,
      ),
      color: context.auraColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          AuraIcon(
            Icons.error_outline,
            color: context.auraColors.error,
            size: AuraIconSize.small,
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.auraColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required bool isLoading,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.spacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.auraColors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AuraButton(
              variant: AuraButtonVariant.outlined,
              onPressed: onCancel,
              child: const TextLocale(LocaleKeys.common_cancel),
            ),
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Expanded(
            child: AuraButton(
              onPressed: onSave,
              isLoading: isLoading,
              child: const TextLocale(LocaleKeys.common_save),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(mcpFormProvider.notifier);
    final success = await notifier.submit();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MCP Server configuration saved (TODO: implement)'),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

/// Widget for selecting the transport type
class _TransportSelector extends StatelessWidget {
  const _TransportSelector({
    required this.value,
    required this.onChanged,
  });

  final McpTransportType value;
  final ValueChanged<McpTransportType> onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.xs,
      children: [
        const AuraText(
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
          child: TextLocale(LocaleKeys.mcp_modal_fields_transport_label),
        ),
        AuraButtonGroup<McpTransportType>.single(
          selectedValue: value,
          onChanged: onChanged,
          items: const [
            AuraButtonGroupItem(
              value: McpTransportType.sse,
              child: TextLocale(
                LocaleKeys.mcp_modal_transport_sse,
              ),
            ),
            AuraButtonGroupItem(
              value: McpTransportType.streamableHttp,
              child: TextLocale(
                LocaleKeys.mcp_modal_transport_streamable_http,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for toggling HTTP/2 support
class _Http2Toggle extends StatelessWidget {
  const _Http2Toggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: AuraColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AuraSpacing.none,
            children: [
              AuraText(
                child: TextLocale(LocaleKeys.mcp_modal_fields_use_http2_label),
              ),
              AuraText(
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
                child: TextLocale(LocaleKeys.mcp_modal_fields_use_http2_hint),
              ),
            ],
          ),
        ),
        AuraSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Widget for selecting the authentication type
class _AuthenticationSelector extends StatelessWidget {
  const _AuthenticationSelector({
    required this.value,
    required this.availableTypes,
    required this.onChanged,
  });

  final McpAuthenticationType value;
  final List<McpAuthenticationType> availableTypes;
  final ValueChanged<McpAuthenticationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.xs,
      children: [
        const AuraText(
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
          child: TextLocale(LocaleKeys.mcp_modal_fields_authentication_label),
        ),
        AuraButtonGroup<McpAuthenticationType>.single(
          selectedValue: value,
          onChanged: onChanged,
          items: availableTypes.map((type) {
            return AuraButtonGroupItem(
              value: type,
              child: TextLocale(_getAuthTypeLocaleKey(type)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getAuthTypeLocaleKey(McpAuthenticationType type) {
    switch (type) {
      case McpAuthenticationType.none:
        return LocaleKeys.mcp_modal_auth_none;
      case McpAuthenticationType.oauth:
        return LocaleKeys.mcp_modal_auth_oauth;
      case McpAuthenticationType.bearerToken:
        return LocaleKeys.mcp_modal_auth_bearer_token;
    }
  }
}

/// Widget containing OAuth configuration fields
class _OAuthFields extends StatelessWidget {
  const _OAuthFields({
    required this.clientIdController,
    required this.tokenEndpointController,
    required this.authEndpointController,
    required this.onClientIdChanged,
    required this.onTokenEndpointChanged,
    required this.onAuthEndpointChanged,
  });

  final TextEditingController clientIdController;
  final TextEditingController tokenEndpointController;
  final TextEditingController authEndpointController;
  final ValueChanged<String> onClientIdChanged;
  final ValueChanged<String> onTokenEndpointChanged;
  final ValueChanged<String> onAuthEndpointChanged;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      style: AuraCardStyle.border,
      child: AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AuraSpacing.md,
        children: [
          AuraRow(
            spacing: AuraSpacing.sm,
            children: [
              AuraIcon(
                Icons.lock_outline,
                size: AuraIconSize.small,
                color: context.auraColors.primary,
              ),
              const AuraText(
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.primary,
                child: TextLocale(LocaleKeys.mcp_modal_oauth_section_title),
              ),
            ],
          ),
          AuraInput(
            controller: clientIdController,
            onChanged: onClientIdChanged,
            label: const TextLocale(
              LocaleKeys.mcp_modal_fields_client_id_label,
            ),
            placeholder: const TextLocale(
              LocaleKeys.mcp_modal_fields_client_id_placeholder,
            ),
          ),
          AuraInput(
            controller: tokenEndpointController,
            onChanged: onTokenEndpointChanged,
            label: const TextLocale(
              LocaleKeys.mcp_modal_fields_token_endpoint_label,
            ),
            placeholder: const TextLocale(
              LocaleKeys.mcp_modal_fields_token_endpoint_placeholder,
            ),
          ),
          AuraInput(
            controller: authEndpointController,
            onChanged: onAuthEndpointChanged,
            label: const TextLocale(
              LocaleKeys.mcp_modal_fields_auth_endpoint_label,
            ),
            placeholder: const TextLocale(
              LocaleKeys.mcp_modal_fields_auth_endpoint_placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for bearer token input
class _BearerTokenField extends StatelessWidget {
  const _BearerTokenField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      style: AuraCardStyle.border,
      child: AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AuraSpacing.md,
        children: [
          AuraRow(
            spacing: AuraSpacing.sm,
            children: [
              AuraIcon(
                Icons.key,
                size: AuraIconSize.small,
                color: context.auraColors.primary,
              ),
              const AuraText(
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.primary,
                child: TextLocale(LocaleKeys.mcp_modal_bearer_section_title),
              ),
            ],
          ),
          AuraInput(
            controller: controller,
            onChanged: onChanged,
            label: const TextLocale(
              LocaleKeys.mcp_modal_fields_bearer_token_label,
            ),
            placeholder: const TextLocale(
              LocaleKeys.mcp_modal_fields_bearer_token_placeholder,
            ),
            hint: const TextLocale(
              LocaleKeys.mcp_modal_fields_bearer_token_hint,
            ),
            obscureText: true,
          ),
        ],
      ),
    );
  }
}
