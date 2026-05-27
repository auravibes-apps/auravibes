// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: avoid-returning-widgets
// Required: Existing helper builders return widgets.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
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
  const AddMcpModal({required this.workspaceId, super.key});

  final String workspaceId;

  /// Shows the add MCP modal as a dialog
  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddMcpModal(workspaceId: workspaceId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.xl),
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            _buildHeader(context),

            // Error message
            _ErrorBanner(workspaceId: workspaceId),

            // Scrollable form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.auraTheme.spacing.md),
                child: Stack(
                  children: [
                    AuraColumn(
                      children: [
                        // Name field (required)
                        _NameInput(workspaceId: workspaceId),

                        // Description field (optional)
                        _DescriptionInput(workspaceId: workspaceId),

                        // URL field (required)
                        _UrlInput(workspaceId: workspaceId),

                        // Transport selector
                        _TransportSelector(workspaceId: workspaceId),

                        // HTTP/2 toggle (only for streamableHttp)
                        AppVisibilityBase(
                          visible: mcpFormProvider(workspaceId).select(
                            (value) => value.showHttp2Toggle,
                          ),
                          child: _Http2Toggle(workspaceId: workspaceId),
                        ),

                        // Authentication selector
                        _AuthenticationSelector(workspaceId: workspaceId),

                        // Bearer token field
                        AppVisibilityBase(
                          visible: mcpFormProvider(workspaceId).select(
                            (value) => value.showBearerTokenField,
                          ),
                          child: _BearerTokenField(workspaceId: workspaceId),
                        ),
                      ],
                      spacing: AuraSpacing.md,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                    ),
                    _LoadingOverlay(workspaceId: workspaceId),
                  ],
                ),
              ),
            ),

            // Footer with action buttons
            _Footer(workspaceId: workspaceId),
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
          const AuraIcon(
            Icons.extension,
            color: AuraColorVariant.primary,
          ),
          const Expanded(
            child: AuraText(
              child: TextLocale(LocaleKeys.mcp_modal_title),
              style: AuraTextStyle.heading6,
            ),
          ),
          AuraIconButton(
            icon: Icons.close,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends ConsumerWidget {
  const _LoadingOverlay({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      mcpFormProvider(workspaceId).select(
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
  const _ErrorBanner({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(
      mcpFormProvider(workspaceId).select(
        (value) => value.errorMessage,
      ),
    );

    if (errorMessage == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.spacing.sm,
        horizontal: context.auraTheme.spacing.md,
      ),
      color: context.auraColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const AuraIcon(
            Icons.error_outline,
            size: AuraIconSize.small,
            color: AuraColorVariant.error,
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
  const _Footer({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      mcpFormProvider(workspaceId).select(
        (value) => value.isSubmitting,
      ),
    );

    final onSave = useCallback(
      () {
        unawaited(
          ref.read(mcpFormProvider(workspaceId).notifier).submit().then((
            success,
          ) {
            if (success && context.mounted) {
              final _ = showAuraSnackBar(
                context: context,
                content: const Text(
                  'MCP Server configuration saved (TODO: implement)',
                ),
                variant: AuraSnackBarVariant.success,
              );
              Navigator.of(context).pop();
            }
          }),
        );
      },
      [ref, context, workspaceId],
    );
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
              onPressed: () => Navigator.of(context).pop(),
              child: const TextLocale(LocaleKeys.common_cancel),
              variant: AuraButtonVariant.outlined,
            ),
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Expanded(
            child: AuraButton(
              onPressed: onSave,
              child: const TextLocale(LocaleKeys.common_save),
              isLoading: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportSelector extends StatelessWidget {
  const _TransportSelector({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AppDropdownBase<McpTransportTypeOptions>(
      value: mcpFormProvider(workspaceId).select(
        (value) => value.transport,
      ),
      onChanged: mcpFormProvider(workspaceId).notifier.select(
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
  const _Http2Toggle({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AppToggleBase(
      labelLocaleKey: LocaleKeys.mcp_modal_fields_use_http2_label,
      hintLocaleKey: LocaleKeys.mcp_modal_fields_use_http2_hint,
      value: mcpFormProvider(workspaceId).select(
        (value) => value.useHttp2,
      ),
      onChanged: mcpFormProvider(workspaceId).notifier.select(
        (notifier) => notifier.setUseHttp2,
      ),
    );
  }
}

/// Renders the available authentication types from [mcpFormProvider]
/// as a localized single-select button group and updates the selected type.
class _AuthenticationSelector extends ConsumerWidget {
  const _AuthenticationSelector({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableTypes = ref.watch(
      mcpFormProvider(workspaceId).select(
        (value) => value.availableAuthTypes,
      ),
    );

    return AppGroupButtonSingleBase<McpAuthenticationTypeOptions>(
      value: mcpFormProvider(workspaceId).select(
        (value) => value.authenticationType,
      ),
      items: availableTypes.map((type) {
        return AuraButtonGroupItem(
          value: type,
          child: TextLocale(_getAuthTypeLocaleKey(type)),
        );
      }).toList(),
      onChanged: mcpFormProvider(workspaceId).notifier.select(
        (value) => value.setAuthenticationType,
      ),
      labelLocaleKey: LocaleKeys.mcp_modal_fields_authentication_label,
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
  const _NameInput({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      labelLocaleKey: LocaleKeys.mcp_modal_fields_name_label,
      placeholderLocaleKey: LocaleKeys.mcp_modal_fields_name_placeholder,
      value: mcpFormProvider(workspaceId).select(
        (value) => value.name,
      ),
      onChanged: mcpFormProvider(workspaceId).notifier.select(
        (value) => value.setName,
      ),
    );
  }
}

class _DescriptionInput extends StatelessWidget {
  const _DescriptionInput({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      labelLocaleKey: LocaleKeys.mcp_modal_fields_description_label,
      placeholderLocaleKey: LocaleKeys.mcp_modal_fields_description_placeholder,
      value: mcpFormProvider(workspaceId).select(
        (value) => value.description,
      ),
      onChanged: mcpFormProvider(workspaceId).notifier.select(
        (value) => value.setDescription,
      ),
    );
  }
}

class _UrlInput extends StatelessWidget {
  const _UrlInput({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      labelLocaleKey: LocaleKeys.mcp_modal_fields_url_label,
      placeholderLocaleKey: LocaleKeys.mcp_modal_fields_url_placeholder,
      value: mcpFormProvider(workspaceId).select(
        (value) => value.url,
      ),
      onChanged: mcpFormProvider(workspaceId).notifier.select(
        (value) => value.setUrl,
      ),
      hintLocaleKey: LocaleKeys.mcp_modal_fields_url_hint,
    );
  }
}

class _BearerTokenField extends StatelessWidget {
  const _BearerTokenField({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AppInputBase(
      labelLocaleKey: LocaleKeys.mcp_modal_fields_bearer_token_label,
      placeholderLocaleKey:
          LocaleKeys.mcp_modal_fields_bearer_token_placeholder,
      value: mcpFormProvider(workspaceId).select(
        (value) => value.bearerToken,
      ),
      onChanged: mcpFormProvider(workspaceId).notifier.select(
        (value) => value.setBearerToken,
      ),
      hintLocaleKey: LocaleKeys.mcp_modal_fields_bearer_token_hint,
      obscureText: true,
    );
  }
}
