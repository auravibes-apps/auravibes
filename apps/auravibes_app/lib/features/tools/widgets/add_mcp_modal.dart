// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/mcp_service/oauth_authentication_canceled_exception.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    return _AddMcpDialog(workspaceId: workspaceId);
  }
}

class const _AddMcpDialog({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef _) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          .circular(context.auraTheme.fromBorderRadius(.xl)),
        ),
      ),
      child: _AddMcpDialogContent(workspaceId: workspaceId),
    );
  }
}

class const _AddMcpDialogContent({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AddMcpDialogLayout(
    workspaceId: workspaceId,
    width: MediaQuery.sizeOf(context).width * 0.9,
    maxHeight: MediaQuery.sizeOf(context).height * 0.85,
  );
}

class const _AddMcpDialogLayout({
  required final String workspaceId,
  required final double width,
  required final double maxHeight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: .new(maxWidth: 450, maxHeight: maxHeight),
    child: _AddMcpDialogColumn(workspaceId: workspaceId),
  );
}

class const _AddMcpDialogColumn({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      const _AddMcpModalHeader(),
      Flexible(child: _AddMcpForm(workspaceId: workspaceId)),
      _Footer(workspaceId: workspaceId),
    ],
  );
}

class const _AddMcpForm({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _McpFormScrollView(workspaceId: workspaceId);
}

class const _McpFormScrollView({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: _McpFormStack(workspaceId: workspaceId),
  );
}

class const _McpFormStack({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _McpFormFields(workspaceId: workspaceId),
      _LoadingOverlay(workspaceId: workspaceId),
    ],
  );
}

class const _McpFormFields({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _McpFormFieldsLayout(
    workspaceId: workspaceId,
    oauthDeviceCode: ref.watch(
      mcpFormProvider(workspaceId).select((value) => value.oauthDeviceCode),
    ),
    showBearerTokenField: ref.watch(
      mcpFormProvider(workspaceId)
          .select((value) => value.showBearerTokenField),
    ),
    showOAuthFields: ref.watch(
      mcpFormProvider(workspaceId).select((value) => value.showOAuthFields),
    ),
  );
}

class const _McpFormFieldsLayout({
  required final String workspaceId,
  required final McpOAuthDeviceCode? oauthDeviceCode,
  required final bool showBearerTokenField,
  required final bool showOAuthFields,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _McpFormFieldChildren(
      workspaceId: workspaceId,
      oauthDeviceCode: oauthDeviceCode,
      showBearerTokenField: showBearerTokenField,
      showOAuthFields: showOAuthFields,
    ).values,
    spacing: .md,
    crossAxisAlignment: .stretch,
  );
}

class _McpFormFieldChildren {
  new({
    required String workspaceId,
    required McpOAuthDeviceCode? oauthDeviceCode,
    required bool showBearerTokenField,
    required bool showOAuthFields,
  }) : values = [
         _ErrorBanner(workspaceId: workspaceId),
         _NameInput(workspaceId: workspaceId),
         _DescriptionInput(workspaceId: workspaceId),
         _UrlInput(workspaceId: workspaceId),
         _TransportSelector(workspaceId: workspaceId),
         _AuthenticationSelector(workspaceId: workspaceId),
         if (showOAuthFields) _OAuthAdvancedSettings(workspaceId: workspaceId),
         if (oauthDeviceCode case final value?)
           _McpOAuthDeviceCodePanel(deviceCode: value),
         Visibility(
           child: _BearerTokenField(workspaceId: workspaceId),
           visible: showBearerTokenField,
         ),
         _VerificationStatus(workspaceId: workspaceId),
       ];

  final List<Widget> values;
}

class const _AddMcpModalHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _McpModalHeaderFrame(
    padding: .all(context.auraTheme.fromSpacing(.md)),
    borderColor: context.auraColors.outline.withValues(
      alpha: AddMcpModal._dividerOpacity,
    ),
  );
}

class const _McpModalHeaderFrame({
  required final EdgeInsets padding,
  required final Color borderColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: .new(color: borderColor)),
    ),
    child: Padding(padding: padding, child: const _McpModalHeaderRow()),
  );
}

class const _McpModalHeaderRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraRow(children: _McpModalHeaderChildren(context).values);
}

class _McpModalHeaderChildren {
  new(BuildContext context)
    : values = [
        const AuraIcon(Icons.extension, tint: .primary),
        const Expanded(
          child: AuraText(
            child: TextLocale(LocaleKeys.mcp_modal_title),
            style: .heading6,
          ),
        ),
        AuraIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];

  final List<Widget> values;
}

class const _LoadingOverlay({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _LoadingOverlayContent(
    isBusy: ref.watch(
      mcpFormProvider(workspaceId)
          .select((value) => value.isSubmitting || value.isTestingConnection),
    ),
    hasDeviceCode:
        ref.watch(
          mcpFormProvider(workspaceId).select((value) => value.oauthDeviceCode),
        ) !=
        null,
  );
}

class const _LoadingOverlayContent({
  required final bool isBusy,
  required final bool hasDeviceCode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isBusy && !hasDeviceCode
      ? _LoadingOverlaySurface(color: context.auraColors.surface)
      : const SizedBox.shrink();
}

class const _LoadingOverlaySurface({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: color.withValues(alpha: 0.6),
      child: const Center(child: AuraLoadingOverlay()),
    ),
  );
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

    return _ErrorBannerContent(message: _displayErrorMessage(errorMessage));
  }
}

String _displayErrorMessage(String errorMessage) => switch (errorMessage) {
  LocaleKeys.tools_screen_mcp_error ||
  LocaleKeys.workspace_capabilities_unsupported_error ||
  LocaleKeys.mcp_modal_verification_required ||
  LocaleKeys.mcp_modal_verification_expired ||
  LocaleKeys.mcp_modal_oauth_configuration ||
  LocaleKeys.mcp_modal_oauth_client_id_required ||
  LocaleKeys.mcp_modal_oauth_registration_failed ||
  LocaleKeys.mcp_modal_oauth_malformed ||
  LocaleKeys.mcp_modal_oauth_cancelled ||
  LocaleKeys.mcp_modal_oauth_expired ||
  LocaleKeys.mcp_modal_oauth_issuer_mismatch ||
  LocaleKeys.mcp_modal_oauth_token_exchange ||
  LocaleKeys.mcp_modal_oauth_discovery => errorMessage.tr(),
  _ => errorMessage,
};

class const _McpOAuthDeviceCodePanel({
  required final McpOAuthDeviceCode deviceCode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.mcp_modal_oauth_device_code_title),
          style: .heading6,
        ),
        const AuraText(
          child: TextLocale(
            LocaleKeys.mcp_modal_oauth_device_code_instructions,
          ),
        ),
        AuraSelectableText(
          deviceCode.userCode,
          style: .heading5,
          tint: .primary,
        ),
        AuraSelectableText(deviceCode.verificationUrl, tint: .primary),
      ],
      spacing: .sm,
      crossAxisAlignment: .stretch,
    ),
  );
}

class const _ErrorBannerContent({required final String message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ErrorBannerSurface(
    message: message,
    padding: .symmetric(
      vertical: context.auraTheme.fromSpacing(.sm),
      horizontal: context.auraTheme.fromSpacing(.md),
    ),
    backgroundColor: context.auraColors.error.withValues(alpha: 0.1),
    textColor: context.auraColors.error,
  );
}

class const _ErrorBannerSurface({
  required final String message,
  required final EdgeInsets padding,
  required final Color backgroundColor,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    color: backgroundColor,
    child: _ErrorBannerRow(message: message, textColor: textColor),
  );
}

class const _ErrorBannerRow({
  required final String message,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AuraIcon(Icons.error_outline, size: .small, tint: .error),
      const AuraSizedBox(width: .sm),
      Expanded(
        child: Text(message, style: .new(color: textColor)),
      ),
    ],
  );
}

class const _VerificationStatus({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      mcpFormProvider(workspaceId).select(
        (value) => (
          isVerified: value.isConnectionVerified,
          toolCount: value.verifiedToolCount,
        ),
      ),
    );

    return _VerificationStatusContent(
      isVerified: state.isVerified,
      toolCount: state.toolCount,
    );
  }
}

class const _VerificationStatusContent({
  required final bool isVerified,
  required final int toolCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return AuraBadge(
      child: AuraRow(
        children: [
          const AuraIcon(Icons.check_circle, size: .small),
          Text(
            LocaleKeys.mcp_modal_verification_success.tr(
              args: [toolCount.toString()],
            ),
          ),
        ],
        spacing: .xs,
        mainAxisSize: .min,
      ),
      variant: .success,
    );
  }
}

class const _Footer({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _watchMcpFooterState(ref, workspaceId);

    return _FooterBar(
      isSubmitting: state.isSubmitting,
      isTestingConnection: state.isTestingConnection,
      isConnectionVerified: state.isConnectionVerified,
      onTestConnection: () =>
          unawaited(_testConnection(context, ref, workspaceId)),
      onSubmit: () => unawaited(_submit(context, ref, workspaceId)),
    );
  }

  Future<void> _testConnection(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final success = await ref
        .read(mcpFormProvider(workspaceId).notifier)
        .testConnection();
    if (!success || !context.mounted) return;

    _showMcpConnectionTestSuccess(context);
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final success = await _submitMcpForm(ref, workspaceId);
    if (!success || !context.mounted) return;

    _showMcpSaveSuccess(context);
    Navigator.of(context).pop();
  }
}

({bool isSubmitting, bool isTestingConnection, bool isConnectionVerified})
_watchMcpFooterState(WidgetRef ref, String workspaceId) => ref.watch(
  mcpFormProvider(workspaceId).select(
    (value) => (
      isSubmitting: value.isSubmitting,
      isTestingConnection: value.isTestingConnection,
      isConnectionVerified: value.isConnectionVerified,
    ),
  ),
);

Future<bool> _submitMcpForm(WidgetRef ref, String workspaceId) =>
    ref.read(mcpFormProvider(workspaceId).notifier).submit();

void _showMcpSaveSuccess(BuildContext context) {
  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.mcp_modal_save_success.tr()),
    variant: .success,
  );
}

void _showMcpConnectionTestSuccess(BuildContext context) {
  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.mcp_modal_test_connection_success.tr()),
    variant: .success,
  );
}

class const _FooterBar({
  required final bool isSubmitting,
  required final bool isTestingConnection,
  required final bool isConnectionVerified,
  required final VoidCallback onTestConnection,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _FooterBarFrame(
    padding: .all(context.auraTheme.fromSpacing(.md)),
    borderColor: context.auraColors.outline.withValues(
      alpha: AddMcpModal._dividerOpacity,
    ),
    isSubmitting: isSubmitting,
    isTestingConnection: isTestingConnection,
    isConnectionVerified: isConnectionVerified,
    onTestConnection: onTestConnection,
    onSubmit: onSubmit,
  );
}

class const _FooterBarFrame({
  required final EdgeInsets padding,
  required final Color borderColor,
  required final bool isSubmitting,
  required final bool isTestingConnection,
  required final bool isConnectionVerified,
  required final VoidCallback onTestConnection,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: .new(color: borderColor)),
    ),
    child: Padding(
      padding: padding,
      child: _FooterButtons(
        isSubmitting: isSubmitting,
        isTestingConnection: isTestingConnection,
        isConnectionVerified: isConnectionVerified,
        onTestConnection: onTestConnection,
        onSubmit: onSubmit,
      ),
    ),
  );
}

class const _FooterButtons({
  required final bool isSubmitting,
  required final bool isTestingConnection,
  required final bool isConnectionVerified,
  required final VoidCallback onTestConnection,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: _FooterCancelButton()),
      const AuraSizedBox(width: .sm),
      Expanded(
        child: _FooterTestConnectionButton(
          isTestingConnection: isTestingConnection,
          onTestConnection: onTestConnection,
        ),
      ),
      const AuraSizedBox(width: .sm),
      Expanded(
        child: _FooterSaveButton(
          isSubmitting: isSubmitting,
          disabled: isTestingConnection || !isConnectionVerified,
          onSubmit: onSubmit,
        ),
      ),
    ],
  );
}

class const _FooterCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
    variant: .outlined,
  );
}

class const _FooterSaveButton({
  required final bool isSubmitting,
  required final bool disabled,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onSubmit,
    child: const TextLocale(LocaleKeys.common_save),
    isLoading: isSubmitting,
    disabled: disabled,
  );
}

class const _FooterTestConnectionButton({
  required final bool isTestingConnection,
  required final VoidCallback onTestConnection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onTestConnection,
    child: const TextLocale(LocaleKeys.mcp_modal_test_connection),
    variant: .outlined,
    isLoading: isTestingConnection,
  );
}

class const _TransportSelector({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _TransportSelectorContent(
        capabilities: _watchMcpCapabilities(ref, workspaceId),
        value: _watchMcpTransport(ref, workspaceId),
        onChanged: _watchMcpTransportChanged(ref, workspaceId),
      );
}

class const _TransportSelectorContent({
  required final WorkspaceCapabilities capabilities,
  required final McpTransportTypeOptions value,
  required final ValueChanged<McpTransportTypeOptions?>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _TransportSelectorChildren(
      capabilities: capabilities,
      value: value,
      onChanged: onChanged,
    ).values,
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class _TransportSelectorChildren {
  new({
    required WorkspaceCapabilities capabilities,
    required McpTransportTypeOptions value,
    required ValueChanged<McpTransportTypeOptions?>? onChanged,
  }) : values = [
         const AuraText(
           child: TextLocale(LocaleKeys.mcp_modal_fields_transport_label),
           style: .bodySmall,
         ),
         AuraDropdownSelector<McpTransportTypeOptions>(
           options: _McpTransportOptions(capabilities).values,
           value: value,
           onChanged: onChanged,
         ),
       ];

  final List<Widget> values;
}

class _McpTransportOptions {
  new(WorkspaceCapabilities capabilities)
    : values = [
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

  final List<AuraDropdownOption<McpTransportTypeOptions>> values;
}

WorkspaceCapabilities _watchMcpCapabilities(
  WidgetRef ref,
  String workspaceId,
) => ref
    .watch(workspaceSessionForRouteProvider(workspaceId))
    .requireValue
    .capabilities;

McpTransportTypeOptions _watchMcpTransport(WidgetRef ref, String workspaceId) =>
    ref.watch(mcpFormProvider(workspaceId).select((state) => state.transport));

ValueChanged<McpTransportTypeOptions?>? _watchMcpTransportChanged(
  WidgetRef ref,
  String workspaceId,
) => ref.watch(
  mcpFormProvider(workspaceId).notifier
      .select((notifier) => notifier.setTransport),
);

/// Renders the available authentication types from [mcpFormProvider]
/// as a localized single-select button group and updates the selected type.
class const _AuthenticationSelector({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _AuthenticationSelectorContent(
        items: _items(_supportedTypes(_watchMcpCapabilities(ref, workspaceId))),
        selectedValue: _watchMcpAuthentication(ref, workspaceId),
        onChanged: _watchMcpAuthenticationChanged(ref, workspaceId),
      );

  static List<McpAuthenticationTypeOptions> _supportedTypes(
    WorkspaceCapabilities capabilities,
  ) => McpAuthenticationTypeOptions.values
      .where(
        (type) => capabilities.mcpAuthentication.contains(switch (type) {
          .none => WorkspaceMcpAuthentication.none,
          .bearerToken => WorkspaceMcpAuthentication.bearerToken,
          .oauth => WorkspaceMcpAuthentication.oauth,
        }),
      )
      .toList();

  static List<AuraButtonGroupItem<McpAuthenticationTypeOptions>> _items(
    List<McpAuthenticationTypeOptions> types,
  ) => types
      .map(
        (type) => AuraButtonGroupItem(
          value: type,
          child: TextLocale(_getAuthTypeLocaleKey(type)),
        ),
      )
      .toList();

  static String _getAuthTypeLocaleKey(McpAuthenticationTypeOptions type) =>
      switch (type) {
        .none => LocaleKeys.mcp_modal_auth_none,
        .oauth => LocaleKeys.mcp_modal_auth_oauth,
        .bearerToken => LocaleKeys.mcp_modal_auth_bearer_token,
      };
}

class const _AuthenticationSelectorContent({
  required final List<AuraButtonGroupItem<McpAuthenticationTypeOptions>> items,
  required final McpAuthenticationTypeOptions selectedValue,
  required final ValueChanged<McpAuthenticationTypeOptions> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _AuthenticationSelectorChildren(
      items: items,
      selectedValue: selectedValue,
      onChanged: onChanged,
    ).values,
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class _AuthenticationSelectorChildren {
  new({
    required List<AuraButtonGroupItem<McpAuthenticationTypeOptions>> items,
    required McpAuthenticationTypeOptions selectedValue,
    required ValueChanged<McpAuthenticationTypeOptions> onChanged,
  }) : values = [
         const AuraText(
           child: TextLocale(LocaleKeys.mcp_modal_fields_authentication_label),
           style: .bodySmall,
         ),
         AuraButtonGroup<McpAuthenticationTypeOptions>.single(
           items: items,
           selectedValue: selectedValue,
           onChanged: onChanged,
         ),
       ];

  final List<Widget> values;
}

class const _OAuthAdvancedSettings({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraAccordion(
    items: [
      AuraAccordionItem(
        title: LocaleKeys.mcp_modal_advanced_settings.tr(context: context),
        child: _OAuthClientIdField(workspaceId: workspaceId),
      ),
    ],
  );
}

class const _OAuthClientIdField({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _McpTextInput(
    workspaceId: workspaceId,
    valueSelector: (value) => value.oauthClientId,
    onChangedSelector: (value) => value.setOAuthClientId,
    placeholder: const TextLocale(
      LocaleKeys.mcp_modal_fields_client_id_placeholder,
    ),
    label: const TextLocale(LocaleKeys.mcp_modal_fields_client_id_label),
    hint: const TextLocale(LocaleKeys.mcp_modal_fields_client_id_hint),
  );
}

McpAuthenticationTypeOptions _watchMcpAuthentication(
  WidgetRef ref,
  String workspaceId,
) => ref.watch(
  mcpFormProvider(workspaceId).select((value) => value.authenticationType),
);

ValueChanged<McpAuthenticationTypeOptions> _watchMcpAuthenticationChanged(
  WidgetRef ref,
  String workspaceId,
) => ref.watch(
  mcpFormProvider(workspaceId).notifier
      .select((value) => value.setAuthenticationType),
);

class const _NameInput({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _McpTextInput(
    workspaceId: workspaceId,
    valueSelector: (value) => value.name,
    onChangedSelector: (value) => value.setName,
    placeholder: const TextLocale(LocaleKeys.mcp_modal_fields_name_placeholder),
    label: const TextLocale(LocaleKeys.mcp_modal_fields_name_label),
  );
}

class const _DescriptionInput({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _McpTextInput(
    workspaceId: workspaceId,
    valueSelector: (value) => value.description,
    onChangedSelector: (value) => value.setDescription,
    placeholder: const TextLocale(
      LocaleKeys.mcp_modal_fields_description_placeholder,
    ),
    label: const TextLocale(LocaleKeys.mcp_modal_fields_description_label),
  );
}

class const _UrlInput({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _McpTextInput(
    workspaceId: workspaceId,
    valueSelector: (value) => value.url,
    onChangedSelector: (value) => value.setUrl,
    placeholder: const TextLocale(LocaleKeys.mcp_modal_fields_url_placeholder),
    label: const TextLocale(LocaleKeys.mcp_modal_fields_url_label),
    hint: const TextLocale(LocaleKeys.mcp_modal_fields_url_hint),
  );
}

class const _BearerTokenField({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _McpTextInput(
    workspaceId: workspaceId,
    valueSelector: (value) => value.bearerToken,
    onChangedSelector: (value) => value.setBearerToken,
    placeholder: const TextLocale(
      LocaleKeys.mcp_modal_fields_bearer_token_placeholder,
    ),
    label: const TextLocale(LocaleKeys.mcp_modal_fields_bearer_token_label),
    hint: const TextLocale(LocaleKeys.mcp_modal_fields_bearer_token_hint),
    obscureText: true,
  );
}

class const _McpTextInput({
  required final String workspaceId,
  required final String Function(McpFormState) valueSelector,
  required final ValueChanged<String> Function(McpFormNotifier)
  onChangedSelector,
  required final Widget placeholder,
  required final Widget label,
  final Widget? hint,
  final bool obscureText = false,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _useMcpTextInputState(ref, workspaceId, (
      valueSelector: valueSelector,
      onChangedSelector: onChangedSelector,
    ));

    return _McpTextInputView(
      state: state,
      placeholder: placeholder,
      label: label,
      hint: hint,
      obscureText: obscureText,
    );
  }
}

typedef _McpTextInputState = ({
  TextEditingController controller,
  ValueChanged<String> onChanged,
});

typedef _McpTextInputSelectors = ({
  String Function(McpFormState) valueSelector,
  ValueChanged<String> Function(McpFormNotifier) onChangedSelector,
});

_McpTextInputState _useMcpTextInputState(
  WidgetRef ref,
  String workspaceId,
  _McpTextInputSelectors selectors,
) {
  final provider = mcpFormProvider(workspaceId);

  return (
    controller: useTextEditingController(
      text: ref.watch(provider.select(selectors.valueSelector)),
    ),
    onChanged: ref.watch(provider.notifier.select(selectors.onChangedSelector)),
  );
}

class _McpTextInputView extends StatelessWidget {
  new({
    required _McpTextInputState state,
    required Widget placeholder,
    required Widget label,
    Widget? hint,
    bool obscureText = false,
  }) : input = AuraInput(
         controller: state.controller,
         placeholder: placeholder,
         label: label,
         hint: hint,
         obscureText: obscureText,
         onChanged: state.onChanged,
       );

  final AuraInput input;

  @override
  Widget build(BuildContext context) => input;
}
