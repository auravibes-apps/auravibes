// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for adding new MCP (Model Context Protocol) servers to the workspace.
class const AddMcpModal({required final String workspaceId, super.key})
    extends ConsumerWidget {
  static const _dividerOpacity = 0.2;

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
        borderRadius: BorderRadius.all(
          Radius.circular(context.auraTheme.fromBorderRadius(.xl)),
        ),
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
                padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
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

                        // Authentication selector.
                        _AuthenticationSelector(workspaceId: workspaceId),

                        // Bearer token field.
                        Visibility(
                          child: _BearerTokenField(workspaceId: workspaceId),
                          visible: ref.watch(
                            mcpFormProvider(workspaceId)
                                .select((value) => value.showBearerTokenField),
                          ),
                        ),
                      ],
                      spacing: .md,
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

class const _AddMcpModalHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.auraColors.outline.withValues(
              alpha: AddMcpModal._dividerOpacity,
            ),
          ),
        ),
      ),
      child: AuraRow(
        children: [
          const AuraIcon(Icons.extension, tint: AuraTint.primary),
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

class const _LoadingOverlay({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      mcpFormProvider(workspaceId).select((value) => value.isSubmitting),
    );

    if (!isSubmitting) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ColoredBox(
        color: context.auraColors.surface.withValues(alpha: 0.6),
        child: const Center(child: AuraLoadingOverlay()),
      ),
    );
  }
}

class const _ErrorBanner({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(
      mcpFormProvider(workspaceId).select((value) => value.errorMessage),
    );

    if (errorMessage == null) {
      return const SizedBox.shrink();
    }
    final displayErrorMessage =
        errorMessage == LocaleKeys.tools_screen_mcp_error
        ? errorMessage.tr()
        : errorMessage;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.sm),
        horizontal: context.auraTheme.fromSpacing(.md),
      ),
      color: context.auraColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const AuraIcon(
            Icons.error_outline,
            size: AuraIconSize.small,
            tint: AuraTint.error,
          ),
          const AuraSizedBox(width: .sm),
          Expanded(
            child: Text(
              displayErrorMessage,
              style: TextStyle(color: context.auraColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class const _Footer({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(
      mcpFormProvider(workspaceId).select((value) => value.isSubmitting),
    );

    return Container(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.auraColors.outline.withValues(
              alpha: AddMcpModal._dividerOpacity,
            ),
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
          const AuraSizedBox(width: .sm),
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

    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.mcp_modal_save_success.tr()),
      variant: AuraSnackBarVariant.success,
    );
    Navigator.of(context).pop();
  }
}

class const _TransportSelector({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue
        .capabilities;
    final options = [
      if (capabilities.mcpTransports.contains(
        WorkspaceMcpTransport.streamableHttp,
      ))
        const AuraDropdownOption(
          value: McpTransportTypeOptions.streamableHttp,
          child: TextLocale(LocaleKeys.mcp_modal_transport_streamable_http),
        ),
      if (capabilities.mcpTransports.contains(WorkspaceMcpTransport.sse))
        const AuraDropdownOption(
          value: McpTransportTypeOptions.sse,
          child: TextLocale(LocaleKeys.mcp_modal_transport_sse),
        ),
    ];

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.mcp_modal_fields_transport_label),
          style: AuraTextStyle.bodySmall,
        ),
        AuraDropdownSelector<McpTransportTypeOptions>(
          options: options,
          value: ref.watch(
            mcpFormProvider(workspaceId).select((value) => value.transport),
          ),
          onChanged: ref.watch(
            mcpFormProvider(workspaceId).notifier
                .select((notifier) => notifier.setTransport),
          ),
        ),
      ],
      spacing: .xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

/// Renders the available authentication types from [mcpFormProvider]
/// as a localized single-select button group and updates the selected type.
class const _AuthenticationSelector({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue
        .capabilities;
    final supportedTypes = McpAuthenticationTypeOptions.values
        .where(
          (type) => capabilities.mcpAuthentication.contains(switch (type) {
            McpAuthenticationTypeOptions.none =>
              WorkspaceMcpAuthentication.none,
            McpAuthenticationTypeOptions.bearerToken =>
              WorkspaceMcpAuthentication.bearerToken,
            McpAuthenticationTypeOptions.oauth =>
              WorkspaceMcpAuthentication.oauth,
          }),
        )
        .toList();

    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.mcp_modal_fields_authentication_label),
          style: AuraTextStyle.bodySmall,
        ),
        AuraButtonGroup<McpAuthenticationTypeOptions>.single(
          items: supportedTypes.map((type) {
            return AuraButtonGroupItem(
              value: type,
              child: TextLocale(_getAuthTypeLocaleKey(type)),
            );
          }).toList(),
          selectedValue: ref.watch(
            mcpFormProvider(workspaceId)
                .select((value) => value.authenticationType),
          ),
          onChanged: ref.watch(
            mcpFormProvider(workspaceId).notifier
                .select((value) => value.setAuthenticationType),
          ),
        ),
      ],
      spacing: .xs,
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

class const _NameInput({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select((value) => value.name),
      ),
    );

    return AuraInput(
      controller: controller,
      placeholder: const TextLocale(
        LocaleKeys.mcp_modal_fields_name_placeholder,
      ),
      label: const TextLocale(LocaleKeys.mcp_modal_fields_name_label),
      onChanged: ref.watch(
        mcpFormProvider(workspaceId).notifier.select((value) => value.setName),
      ),
    );
  }
}

class const _DescriptionInput({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select((value) => value.description),
      ),
    );

    return AuraInput(
      controller: controller,
      placeholder: const TextLocale(
        LocaleKeys.mcp_modal_fields_description_placeholder,
      ),
      label: const TextLocale(LocaleKeys.mcp_modal_fields_description_label),
      onChanged: ref.watch(
        mcpFormProvider(workspaceId).notifier
            .select((value) => value.setDescription),
      ),
    );
  }
}

class const _UrlInput({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select((value) => value.url),
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
        mcpFormProvider(workspaceId).notifier.select((value) => value.setUrl),
      ),
    );
  }
}

class const _BearerTokenField({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(
        mcpFormProvider(workspaceId).select((value) => value.bearerToken),
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
        mcpFormProvider(workspaceId).notifier
            .select((value) => value.setBearerToken),
      ),
    );
  }
}
