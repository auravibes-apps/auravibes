import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_dropdown_base.dart';
import 'package:auravibes_app/widgets/app_group_button_single_base.dart';
import 'package:auravibes_app/widgets/app_input_base.dart';
import 'package:auravibes_app/widgets/app_toggle_base.dart';
import 'package:auravibes_app/widgets/app_visibility_base.dart';
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
            const _ErrorBanner(),

            // Scrollable form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.auraTheme.spacing.md),
                child: Stack(
                  children: [
                    AuraColumn(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AuraSpacing.md,
                      children: [
                        // Name field (required)
                        const _NameInput(),

                        // Description field (optional)
                        const _DescriptionInput(),

                        // URL field (required)
                        const _UrlInput(),

                        // Transport selector
                        const _TransportSelector(),

                        // HTTP/2 toggle (only for streamableHttp)
                        AppVisibilityBase(
                          visible: mcpFormProvider.select(
                            (value) => value.showHttp2Toggle,
                          ),
                          child: const _Http2Toggle(),
                        ),

                        // Authentication selector
                        const _AuthenticationSelector(),

                        // Bearer token field
                        AppVisibilityBase(
                          visible: mcpFormProvider.select(
                            (value) => value.showBearerTokenField,
                          ),
                          child: const _BearerTokenField(),
                        ),
                      ],
                    ),
                    const _LoadingOverlay(),
                  ],
                ),
              ),
            ),

            // Footer with action buttons
            const _Footer(),
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
      child: AuraRow(
        children: [
          AuraIcon(
            Icons.extension,
            color: context.auraColors.primary,
          ),
          const Expanded(
            child: AuraText(
              style: AuraTextStyle.heading6,
              child: TextLocale(LocaleKeys.mcp_modal_title),
            ),
          ),
          AuraIconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends ConsumerWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      mcpFormProvider.select(
        (value) => value.isSubmitting,
      ),
    );

    if (!isSubmitting) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ColoredBox(
        color: context.auraColors.surface.withValues(alpha: 0.6),
        child: const Center(
          child: AuraLoadingOverlay(),
        ),
      ),
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(
      mcpFormProvider.select(
        (value) => value.errorMessage,
      ),
    );

    if (errorMessage == null) {
      return const SizedBox.shrink();
    }
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
              errorMessage,
              style: TextStyle(color: context.auraColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends HookConsumerWidget {
  const _Footer();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      mcpFormProvider.select(
        (value) => value.isSubmitting,
      ),
    );

    final onSave = useCallback(() async {
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
    }, [ref, context]);
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
              onPressed: () => Navigator.of(context).pop(),
              child: const TextLocale(LocaleKeys.common_cancel),
            ),
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Expanded(
            child: AuraButton(
              onPressed: onSave,
              isLoading: isSubmitting,
              child: const TextLocale(LocaleKeys.common_save),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportSelector extends StatelessWidget {
  const _TransportSelector();

  @override
  Widget build(BuildContext context) {
    return AppDropdownBase<McpTransportTypeOptions>(
      value: mcpFormProvider.select(
        (value) => value.transport,
      ),
      onChanged: mcpFormProvider.notifier.select(
        (notifier) => notifier.setTransport,
      ),
      options: const [
        AuraDropdownOption(
          value: McpTransportTypeOptions.streamableHttp,
          child: TextLocale(
            LocaleKeys.mcp_modal_transport_streamable_http,
          ),
        ),
        AuraDropdownOption(
          value: McpTransportTypeOptions.sse,
          child: TextLocale(
            LocaleKeys.mcp_modal_transport_sse,
          ),
        ),
      ],
      labelLocaleKey: LocaleKeys.mcp_modal_fields_transport_label,
    );
  }
}

class _Http2Toggle extends StatelessWidget {
  const _Http2Toggle();

  @override
  Widget build(BuildContext context) {
    return AppToggleBase(
      value: mcpFormProvider.select(
        (value) => value.useHttp2,
      ),
      onChanged: mcpFormProvider.notifier.select(
        (notifier) => notifier.setUseHttp2,
      ),
      hintLocaleKey: LocaleKeys.mcp_modal_fields_use_http2_hint,
      labelLocaleKey: LocaleKeys.mcp_modal_fields_use_http2_label,
    );
  }
}

/// Widget for selecting the authentication type
class _AuthenticationSelector extends ConsumerWidget {
  const _AuthenticationSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableTypes = ref.watch(
      mcpFormProvider.select(
        (value) => value.availableAuthTypes,
      ),
    );

    return AppGroupButtonSingleBase(
      items: availableTypes.map((type) {
        return AuraButtonGroupItem(
          value: type,
          child: TextLocale(_getAuthTypeLocaleKey(type)),
        );
      }).toList(),

      labelLocaleKey: LocaleKeys.mcp_modal_fields_authentication_label,
      onChanged: mcpFormProvider.notifier.select(
        (value) => value.setAuthenticationType,
      ),
      value: mcpFormProvider.select(
        (value) => value.authenticationType,
      ),
    );
  }

  String _getAuthTypeLocaleKey(McpAuthenticationTypeOptions type) {
    switch (type) {
      case .none:
        return LocaleKeys.mcp_modal_auth_none;
      case .oauth:
        return LocaleKeys.mcp_modal_auth_oauth;
      case .bearerToken:
        return LocaleKeys.mcp_modal_auth_bearer_token;
    }
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput();

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      value: mcpFormProvider.select(
        (value) => value.name,
      ),
      onChanged: mcpFormProvider.notifier.select((value) => value.setName),

      labelLocaleKey: LocaleKeys.mcp_modal_fields_name_label,
      placeholderLocaleKey: LocaleKeys.mcp_modal_fields_name_placeholder,
    );
  }
}

class _DescriptionInput extends StatelessWidget {
  const _DescriptionInput();

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      value: mcpFormProvider.select(
        (value) => value.description,
      ),
      onChanged: mcpFormProvider.notifier.select(
        (value) => value.setDescription,
      ),
      labelLocaleKey: LocaleKeys.mcp_modal_fields_description_label,
      placeholderLocaleKey: LocaleKeys.mcp_modal_fields_description_placeholder,
    );
  }
}

class _UrlInput extends StatelessWidget {
  const _UrlInput();

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      value: mcpFormProvider.select(
        (value) => value.url,
      ),
      onChanged: mcpFormProvider.notifier.select(
        (value) => value.setUrl,
      ),
      labelLocaleKey: LocaleKeys.mcp_modal_fields_url_label,
      placeholderLocaleKey: LocaleKeys.mcp_modal_fields_url_placeholder,
      hintLocaleKey: LocaleKeys.mcp_modal_fields_url_hint,
    );
  }
}

class _BearerTokenField extends StatelessWidget {
  const _BearerTokenField();

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      value: mcpFormProvider.select(
        (value) => value.bearerToken,
      ),
      onChanged: mcpFormProvider.notifier.select(
        (value) => value.setBearerToken,
      ),
      labelLocaleKey: LocaleKeys.mcp_modal_fields_bearer_token_label,
      placeholderLocaleKey:
          LocaleKeys.mcp_modal_fields_bearer_token_placeholder,
      hintLocaleKey: LocaleKeys.mcp_modal_fields_bearer_token_hint,
      obscureText: true,
    );
  }
}
