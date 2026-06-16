// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for adding new MCP (Model Context Protocol) servers to the workspace.
class AddMcpModal extends ConsumerWidget {
  const AddMcpModal({required this.workspaceId, super.key});

  final String workspaceId;

  /// Shows the add MCP modal as a dialog.
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
            // Header with close button.
            const _AddMcpModalHeader(),

            // Scrollable form content.
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.auraTheme.spacing.md),
                child: Stack(
                  children: [
                    AuraColumn(
                      children: [
                        // Error message.
                        _ErrorBanner(workspaceId: workspaceId),

                        // Name field (required).
                        _NameInput(workspaceId: workspaceId),

                        // Description field (optional).
                        _DescriptionInput(workspaceId: workspaceId),

                        // URL field (required).
                        _UrlInput(workspaceId: workspaceId),

                        // Transport selector.
                        _TransportSelector(workspaceId: workspaceId),

                        // HTTP/2 toggle (only for streamableHttp).
                        Visibility(
                          child: _Http2Toggle(workspaceId: workspaceId),
                          visible: ref.watch(
                            mcpFormProvider(workspaceId).select(
                              (value) => value.showHttp2Toggle,
                            ),
                          ),
                        ),

                        // Authentication selector.
                        _AuthenticationSelector(workspaceId: workspaceId),

                        // Bearer token field.
                        Visibility(
                          child: _BearerTokenField(workspaceId: workspaceId),
                          visible: ref.watch(
                            mcpFormProvider(workspaceId).select(
                              (value) => value.showBearerTokenField,
                            ),
                          ),
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

            // Footer with action buttons.
            _Footer(workspaceId: workspaceId),
          ],
        ),
      ),
    );
  }
}

class _AddMcpModalHeader extends StatelessWidget {
  const _AddMcpModalHeader();

  @override
  Widget build(BuildContext context) {
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

class _Footer extends ConsumerWidget {
  const _Footer({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      mcpFormProvider(workspaceId).select(
        (value) => value.isSubmitting,
      ),
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
              onPressed: () => unawaited(_submit(context, ref, workspaceId)),
              child: const TextLocale(LocaleKeys.common_save),
              isLoading: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final success = await ref
        .read(mcpFormProvider(workspaceId).notifier)
        .submit();
    if (!success || !context.mounted) return;

    final _ = showAuraSnackBar(
      context: context,
      content: Text(LocaleKeys.mcp_modal_save_success.tr()),
      variant: AuraSnackBarVariant.success,
    );
    Navigator.of(context).pop();
  }
}

class _TransportSelector extends ConsumerWidget {
  const _TransportSelector({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.mcp_modal_fields_transport_label),
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
        ),
        AuraDropdownSelector<McpTransportTypeOptions>(
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
          value: ref.watch(
            mcpFormProvider(workspaceId).select(
              (value) => value.transport,
            ),
          ),
          onChanged: ref.watch(
            mcpFormProvider(workspaceId).notifier.select(
              (notifier) => notifier.setTransport,
            ),
          ),
        ),
      ],
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class _Http2Toggle extends ConsumerWidget {
  const _Http2Toggle({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useHttp2 = ref.watch(
      mcpFormProvider(workspaceId).select(
        (value) => value.useHttp2,
      ),
    );

    return Row(
      children: [
        const Expanded(
          child: AuraColumn(
            children: [
              AuraText(
                child: TextLocale(LocaleKeys.mcp_modal_fields_use_http2_label),
              ),
              AuraText(
                child: TextLocale(LocaleKeys.mcp_modal_fields_use_http2_hint),
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
              ),
            ],
            spacing: AuraSpacing.none,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
        AuraSwitch(
          value: useHttp2,
          onChanged: ref.watch(
            mcpFormProvider(workspaceId).notifier.select(
              (notifier) => notifier.setUseHttp2,
            ),
          ),
        ),
      ],
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

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.mcp_modal_fields_authentication_label),
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
        ),
        AuraButtonGroup<McpAuthenticationTypeOptions>.single(
          items: availableTypes.map((type) {
            return AuraButtonGroupItem(
              value: type,
              child: TextLocale(_getAuthTypeLocaleKey(type)),
            );
          }).toList(),
          selectedValue: ref.watch(
            mcpFormProvider(workspaceId).select(
              (value) => value.authenticationType,
            ),
          ),
          onChanged: ref.watch(
            mcpFormProvider(workspaceId).notifier.select(
              (value) => value.setAuthenticationType,
            ),
          ),
        ),
      ],
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
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

class _NameInput extends HookConsumerWidget {
  const _NameInput({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select(
          (value) => value.name,
        ),
      ),
    );

    return AuraInput(
      controller: controller,
      placeholder: const TextLocale(
        LocaleKeys.mcp_modal_fields_name_placeholder,
      ),
      label: const TextLocale(LocaleKeys.mcp_modal_fields_name_label),
      onChanged: ref.watch(
        mcpFormProvider(workspaceId).notifier.select(
          (value) => value.setName,
        ),
      ),
    );
  }
}

class _DescriptionInput extends HookConsumerWidget {
  const _DescriptionInput({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select(
          (value) => value.description,
        ),
      ),
    );

    return AuraInput(
      controller: controller,
      placeholder: const TextLocale(
        LocaleKeys.mcp_modal_fields_description_placeholder,
      ),
      label: const TextLocale(LocaleKeys.mcp_modal_fields_description_label),
      onChanged: ref.watch(
        mcpFormProvider(workspaceId).notifier.select(
          (value) => value.setDescription,
        ),
      ),
    );
  }
}

class _UrlInput extends HookConsumerWidget {
  const _UrlInput({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select(
          (value) => value.url,
        ),
      ),
    );

    return AuraInput(
      controller: controller,
      placeholder: const TextLocale(
        LocaleKeys.mcp_modal_fields_url_placeholder,
      ),
      label: const TextLocale(LocaleKeys.mcp_modal_fields_url_label),
      hint: const TextLocale(LocaleKeys.mcp_modal_fields_url_hint),
      onChanged: ref.watch(
        mcpFormProvider(workspaceId).notifier.select(
          (value) => value.setUrl,
        ),
      ),
    );
  }
}

class _BearerTokenField extends HookConsumerWidget {
  const _BearerTokenField({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select(
          (value) => value.bearerToken,
        ),
      ),
    );

    return AuraInput(
      controller: controller,
      placeholder: const TextLocale(
        LocaleKeys.mcp_modal_fields_bearer_token_placeholder,
      ),
      label: const TextLocale(LocaleKeys.mcp_modal_fields_bearer_token_label),
      hint: const TextLocale(LocaleKeys.mcp_modal_fields_bearer_token_hint),
      obscureText: true,
      onChanged: ref.watch(
        mcpFormProvider(workspaceId).notifier.select(
          (value) => value.setBearerToken,
        ),
      ),
    );
  }
}
