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
    showBearerTokenField: ref.watch(
      mcpFormProvider(workspaceId)
          .select((value) => value.showBearerTokenField),
    ),
  );
}

class const _McpFormFieldsLayout({
  required final String workspaceId,
  required final bool showBearerTokenField,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _McpFormFieldChildren(
      workspaceId: workspaceId,
      showBearerTokenField: showBearerTokenField,
    ).values,
    spacing: .md,
    crossAxisAlignment: .stretch,
  );
}

class _McpFormFieldChildren {
  new({required String workspaceId, required bool showBearerTokenField})
    : values = [
        _ErrorBanner(workspaceId: workspaceId),
        _NameInput(workspaceId: workspaceId),
        _DescriptionInput(workspaceId: workspaceId),
        _UrlInput(workspaceId: workspaceId),
        _TransportSelector(workspaceId: workspaceId),
        _AuthenticationSelector(workspaceId: workspaceId),
        Visibility(
          child: _BearerTokenField(workspaceId: workspaceId),
          visible: showBearerTokenField,
        ),
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
    isSubmitting: ref.watch(
      mcpFormProvider(workspaceId).select((value) => value.isSubmitting),
    ),
  );
}

class const _LoadingOverlayContent({required final bool isSubmitting})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isSubmitting
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

String _displayErrorMessage(String errorMessage) =>
    errorMessage == LocaleKeys.tools_screen_mcp_error
    ? errorMessage.tr()
    : errorMessage;

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

class const _Footer({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _FooterBar(
    isSubmitting: ref.watch(
      mcpFormProvider(workspaceId).select((value) => value.isSubmitting),
    ),
    onSubmit: () => unawaited(_submit(context, ref, workspaceId)),
  );

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

Future<bool> _submitMcpForm(WidgetRef ref, String workspaceId) =>
    ref.read(mcpFormProvider(workspaceId).notifier).submit();

void _showMcpSaveSuccess(BuildContext context) {
  final _ = AuraSnackBars.show(
    context: context,
    content: Text(LocaleKeys.mcp_modal_save_success.tr()),
    variant: .success,
  );
}

class const _FooterBar({
  required final bool isSubmitting,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _FooterBarFrame(
    padding: .all(context.auraTheme.fromSpacing(.md)),
    borderColor: context.auraColors.outline.withValues(
      alpha: AddMcpModal._dividerOpacity,
    ),
    isSubmitting: isSubmitting,
    onSubmit: onSubmit,
  );
}

class const _FooterBarFrame({
  required final EdgeInsets padding,
  required final Color borderColor,
  required final bool isSubmitting,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: .new(color: borderColor)),
    ),
    child: Padding(
      padding: padding,
      child: _FooterButtons(isSubmitting: isSubmitting, onSubmit: onSubmit),
    ),
  );
}

class const _FooterButtons({
  required final bool isSubmitting,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: _FooterCancelButton()),
      const AuraSizedBox(width: .sm),
      Expanded(
        child: _FooterSaveButton(
          isSubmitting: isSubmitting,
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
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onSubmit,
    child: const TextLocale(LocaleKeys.common_save),
    isLoading: isSubmitting,
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
