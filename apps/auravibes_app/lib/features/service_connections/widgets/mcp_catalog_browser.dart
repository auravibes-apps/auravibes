import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_catalog_installation.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_catalog_sign_in_required.dart';
import 'package:auravibes_app/features/service_connections/providers/mcp_catalog_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/install_mcp_catalog_entry_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/mcp_service/mcp_oauth_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class const McpCatalogBrowser({required final String workspaceId, super.key})
    extends ConsumerStatefulWidget {
  static Future<bool?> show(BuildContext context, String workspaceId) =>
      showDialog<bool>(
        context: context,
        builder: (_) => McpCatalogBrowser(workspaceId: workspaceId),
      );

  @override
  ConsumerState<McpCatalogBrowser> createState() => _McpCatalogBrowserState();
}

class _McpCatalogBrowserState extends ConsumerState<McpCatalogBrowser> {
  static const int _separatorCodePoint = 183;

  final TextEditingController _search = .new();
  final Map<String, TextEditingController> _fields = {};
  String _searchQuery = '';
  McpCatalogListing? _listing;
  McpCatalogConnectionOption? _option;
  McpOAuthDeviceCode? _deviceCode;
  String? _transport;
  String? _authType;
  String? _verificationId;
  String? _errorKey;
  int? _toolCount;
  bool _busy = false;

  @override
  void dispose() {
    _discardVerification();
    _search.dispose();
    _clearFields();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _McpCatalogDialogView(owner: this);

  void _updateState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }
}

extension _McpCatalogSelectionActions on _McpCatalogBrowserState {
  void _clearFields() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _fields.clear();
  }

  void _discardVerification() {
    final id = _verificationId;
    _verificationId = null;
    if (id == null) return;
    unawaited(
      ref.read(mcpConnectionProvider.notifier).discardPreparedMcpConnection(id),
    );
  }

  void _select(McpCatalogListing listing, McpCatalogConnectionOption option) {
    _discardVerification();
    _clearFields();
    for (final field in option.fields) {
      _fields[field.key] = TextEditingController();
    }
    _updateState(() {
      _listing = listing;
      _option = option;
      _errorKey = null;
      _deviceCode = null;
      _toolCount = null;
    });
  }

  void _back() {
    _discardVerification();
    _clearFields();
    _updateState(() {
      _listing = null;
      _option = null;
      _errorKey = null;
      _toolCount = null;
      _deviceCode = null;
    });
  }

  McpCatalogInstallation? _request() {
    final listing = _listing;
    final option = _option;
    if (listing == null || option == null) return null;

    return McpCatalogInstallation(
      workspaceId: widget.workspaceId,
      listing: listing,
      option: option,
      values: _fields.map((key, controller) => MapEntry(key, controller.text)),
    );
  }

  void _fieldChanged() {
    _discardVerification();
    _updateState(() {
      _toolCount = null;
      _errorKey = null;
    });
  }

  void _setOAuthDeviceCode(McpOAuthDeviceCode code) {
    _updateState(() => _deviceCode = code);
  }

  void _updateSearch(String value) => _updateState(() => _searchQuery = value);

  void _updateTransport(String? value) =>
      _updateState(() => _transport = value);

  void _updateAuthentication(String? value) =>
      _updateState(() => _authType = value);
}

extension _McpCatalogUseCaseActions on _McpCatalogBrowserState {
  InstallMcpCatalogEntryUseCase get _installUseCase =>
      InstallMcpCatalogEntryUseCase(
        prepare: _prepareMcpCatalogEntry,
        commit: _commitMcpCatalogEntry,
      );

  Future<McpConnectionVerification> _prepareMcpCatalogEntry(
    McpServerFormToCreate form,
    String workspaceId,
  ) => ref
      .read(mcpConnectionProvider.notifier)
      .prepareMcpConnection(
        form,
        workspaceId: workspaceId,
        onOAuthDeviceCode: _setOAuthDeviceCode,
      );

  Future<void> _commitMcpCatalogEntry(
    McpServerFormToCreate form,
    String workspaceId,
    String verificationId,
  ) => ref
      .read(mcpConnectionProvider.notifier)
      .commitPreparedMcpConnection(
        form,
        workspaceId: workspaceId,
        verificationId: verificationId,
      );
}

extension _McpCatalogVerificationActions on _McpCatalogBrowserState {
  Future<void> _verify() async {
    final request = _request();
    if (request == null || _busy || !_beginVerification(request)) return;
    await _runVerification(request);
  }

  bool _beginVerification(McpCatalogInstallation request) {
    if (request.missingRequiredFields.isNotEmpty) {
      _updateState(() => _errorKey = LocaleKeys.mcp_catalog_missing_fields);

      return false;
    }
    _updateState(() {
      _busy = true;
      _errorKey = null;
      _toolCount = null;
    });

    return true;
  }

  Future<void> _runVerification(McpCatalogInstallation request) async {
    try {
      _acceptVerification(await _installUseCase.verify(request));
    } on Object {
      _setCatalogError(LocaleKeys.mcp_catalog_verification_error);
    } finally {
      _finishCatalogRequest();
    }
  }

  void _acceptVerification(McpConnectionVerification verification) {
    if (!mounted) return;
    _updateState(() {
      _verificationId = verification.id;
      _toolCount = verification.toolCount;
    });
  }
}

extension _McpCatalogInstallActions on _McpCatalogBrowserState {
  Future<void> _install() async {
    final request = _request();
    final verificationId = _verificationId;
    if (request == null || verificationId == null || _busy) return;
    _updateState(() {
      _busy = true;
      _errorKey = null;
    });
    await _runInstall(request, verificationId);
  }

  Future<void> _runInstall(
    McpCatalogInstallation request,
    String verificationId,
  ) async {
    try {
      await _installUseCase.install(request, verificationId);
      _completeCatalogInstall();
    } on Object {
      _setCatalogError(LocaleKeys.mcp_catalog_install_error);
    } finally {
      _finishCatalogRequest();
    }
  }

  void _completeCatalogInstall() {
    if (!mounted) return;
    _verificationId = null;
    ref.invalidate(serviceConnectionsProvider(widget.workspaceId));
    Navigator.of(context).pop(true);
  }

  void _setCatalogError(String errorKey) {
    _updateState(() => _errorKey = errorKey);
  }

  void _finishCatalogRequest() {
    _updateState(() => _busy = false);
  }
}

class const _McpCatalogDialogView({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocaleKeys.mcp_catalog_title.tr()),
    content: _McpCatalogDialogContent(owner: owner),
    actions: [
      if (owner._listing != null) _McpCatalogBackButton(owner: owner),
      _McpCatalogCancelButton(owner: owner),
      if (owner._listing != null) ...[
        _McpCatalogVerifyButton(owner: owner),
        _McpCatalogInstallButton(owner: owner),
      ],
    ],
  );
}

class const _McpCatalogDialogContent({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final listing = owner._listing;
    final option = owner._option;

    return SizedBox(
      width: 520,
      height: 560,
      child: listing == null || option == null
          ? _McpCatalogBrowseContent(owner: owner)
          : _McpCatalogConfigureContent(
              owner: owner,
              listing: listing,
              option: option,
            ),
    );
  }
}

class const _McpCatalogBackButton({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: owner._busy ? null : owner._back,
    child: Text(LocaleKeys.mcp_catalog_back.tr()),
  );
}

class const _McpCatalogCancelButton({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: owner._busy ? null : () => Navigator.of(context).pop(false),
    child: Text(LocaleKeys.common_cancel.tr()),
  );
}

class const _McpCatalogVerifyButton({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: owner._busy ? null : () => unawaited(owner._verify()),
    child: Text(LocaleKeys.mcp_catalog_verify.tr()),
  );
}

class const _McpCatalogInstallButton({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: owner._busy || owner._verificationId == null
        ? null
        : () => unawaited(owner._install()),
    child: Text(LocaleKeys.mcp_catalog_install.tr()),
  );
}

class const _McpCatalogBrowseContent({
  required final _McpCatalogBrowserState owner,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(mcpCatalogProvider(owner.widget.workspaceId));
    final session = ref.watch(
      workspaceSessionForRouteProvider(owner.widget.workspaceId),
    );

    return _McpCatalogBrowseResult(
      owner: owner,
      listings: listings,
      session: session,
    );
  }
}

class const _McpCatalogBrowseResult({
  required final _McpCatalogBrowserState owner,
  required final AsyncValue<List<McpCatalogListing>> listings,
  required final AsyncValue<WorkspaceSession> session,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (_mcpCatalogBrowseLoading(listings, session)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mcpCatalogBrowseHasError(listings, session)) {
      return _McpCatalogLoadError(
        owner: owner,
        requiresSignIn: listings.error is McpCatalogSignInRequired,
      );
    }

    return _McpCatalogListingList(
      owner: owner,
      available: listings.requireValue,
      capabilities: session.requireValue.capabilities,
    );
  }
}

bool _mcpCatalogBrowseLoading(
  AsyncValue<List<McpCatalogListing>> listings,
  AsyncValue<WorkspaceSession> session,
) => listings.isLoading || session.isLoading;

bool _mcpCatalogBrowseHasError(
  AsyncValue<List<McpCatalogListing>> listings,
  AsyncValue<WorkspaceSession> session,
) => listings.hasError || session.hasError;

class const _McpCatalogLoadError({
  required final _McpCatalogBrowserState owner,
  required final bool requiresSignIn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      children: [
        _McpCatalogLoadErrorMessage(requiresSignIn: requiresSignIn),
        _McpCatalogReloadButton(owner: owner),
      ],
    ),
  );
}

class const _McpCatalogLoadErrorMessage({required final bool requiresSignIn})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    (requiresSignIn
            ? LocaleKeys.mcp_catalog_sign_in_required
            : LocaleKeys.mcp_catalog_load_error)
        .tr(),
  );
}

class const _McpCatalogReloadButton({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () =>
        owner.ref.invalidate(mcpCatalogProvider(owner.widget.workspaceId)),
    child: Text(LocaleKeys.common_reload.tr()),
  );
}

class const _McpCatalogListingList({
  required final _McpCatalogBrowserState owner,
  required final List<McpCatalogListing> available,
  required final WorkspaceCapabilities capabilities,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filtered = filterMcpCatalog(available, (
      query: owner._searchQuery,
      transport: owner._transport,
      authType: owner._authType,
    ));

    return Column(
      children: [
        _McpCatalogSearchInput(owner: owner),
        _McpCatalogFilterRow(owner: owner),
        const SizedBox(height: 8),
        _McpCatalogListingResults(
          owner: owner,
          available: available,
          filtered: filtered,
          capabilities: capabilities,
        ),
      ],
    );
  }
}

class const _McpCatalogSearchInput({
  required final _McpCatalogBrowserState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: owner._search,
    decoration: .new(labelText: LocaleKeys.mcp_catalog_search.tr()),
    onChanged: owner._updateSearch,
  );
}

class const _McpCatalogFilterRow({required final _McpCatalogBrowserState owner})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _McpCatalogFilterInput(
          labelKey: LocaleKeys.mcp_catalog_transport,
          value: owner._transport,
          options: const ['streamableHttp', 'sse'],
          onChanged: owner._updateTransport,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _McpCatalogFilterInput(
          labelKey: LocaleKeys.mcp_catalog_authentication,
          value: owner._authType,
          options: const [
            'none',
            'oauth',
            'bearerToken',
            'apiKey',
            'httpHeaders',
          ],
          onChanged: owner._updateAuthentication,
        ),
      ),
    ],
  );
}

class const _McpCatalogFilterInput({
  required final String labelKey,
  required final String? value,
  required final List<String> options,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
    items: [
      DropdownMenuItem(child: Text(LocaleKeys.mcp_catalog_all.tr())),
      for (final option in options)
        DropdownMenuItem(value: option, child: Text(option)),
    ],
    initialValue: value,
    onChanged: onChanged,
    decoration: .new(labelText: labelKey.tr()),
  );
}

class const _McpCatalogListingResults({
  required final _McpCatalogBrowserState owner,
  required final List<McpCatalogListing> available,
  required final List<McpCatalogListing> filtered,
  required final WorkspaceCapabilities capabilities,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) {
      return Expanded(
        child: _McpCatalogEmptyResults(isEmpty: available.isEmpty),
      );
    }

    return Expanded(
      child: _McpCatalogListingTiles(
        owner: owner,
        listings: filtered,
        capabilities: capabilities,
      ),
    );
  }
}

class const _McpCatalogEmptyResults({required final bool isEmpty})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      (isEmpty ? LocaleKeys.mcp_catalog_empty : LocaleKeys.mcp_catalog_no_match)
          .tr(),
    ),
  );
}

class const _McpCatalogListingTiles({
  required final _McpCatalogBrowserState owner,
  required final List<McpCatalogListing> listings,
  required final WorkspaceCapabilities capabilities,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final listing in listings)
        for (final option in listing.options)
          if (owner._authType == null || option.authType == owner._authType)
            _McpCatalogEntryTile(
              listing: listing,
              option: option,
              capabilities: capabilities,
              onTap: () => owner._select(listing, option),
            ),
    ],
  );
}

class const _McpCatalogEntryTile({
  required final McpCatalogListing listing,
  required final McpCatalogConnectionOption option,
  required final WorkspaceCapabilities capabilities,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  bool get _supported =>
      _supportsTransport(listing.transport, capabilities) &&
      _supportsOption(option.authType, capabilities);

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(_title()),
    subtitle: Text(_subtitle()),
    isThreeLine: true,
    onTap: _supported ? onTap : null,
  );

  String _title() =>
      '${listing.name} '
      '${String.fromCharCode(_McpCatalogBrowserState._separatorCodePoint)} '
      '${option.name}';

  String _subtitle() =>
      '${listing.description}\n${listing.transport}${_unsupportedSuffix()}';

  String _unsupportedSuffix() =>
      _supported ? '' : '\n${LocaleKeys.mcp_catalog_unsupported_option.tr()}';
}

class const _McpCatalogConfigureContent({
  required final _McpCatalogBrowserState owner,
  required final McpCatalogListing listing,
  required final McpCatalogConnectionOption option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      _McpCatalogConfigurationTitle(listing: listing, option: option),
      Text(listing.description),
      const SizedBox(height: 12),
      _McpCatalogCredentialFields(owner: owner, fields: option.fields),
      _McpCatalogDeviceCode(code: owner._deviceCode),
      _McpCatalogFeedback(
        isBusy: owner._busy,
        toolCount: owner._toolCount,
        errorKey: owner._errorKey,
      ),
    ],
  );
}

class const _McpCatalogConfigurationTitle({
  required final McpCatalogListing listing,
  required final McpCatalogConnectionOption option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    '${listing.name} '
    '${String.fromCharCode(_McpCatalogBrowserState._separatorCodePoint)} '
    '${option.name}',
    style: Theme.of(context).textTheme.titleMedium,
  );
}

class const _McpCatalogCredentialFields({
  required final _McpCatalogBrowserState owner,
  required final List<McpCatalogCredentialField> fields,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final field in fields)
        _McpCatalogCredentialInput(owner: owner, field: field),
    ],
  );
}

class const _McpCatalogCredentialInput({
  required final _McpCatalogBrowserState owner,
  required final McpCatalogCredentialField field,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _McpCatalogCredentialTextField(owner: owner, field: field),
        if (field.helpUrl case final url?) _McpCatalogFieldHelpLink(url: url),
      ],
    );
  }
}

class const _McpCatalogCredentialTextField({
  required final _McpCatalogBrowserState owner,
  required final McpCatalogCredentialField field,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => TextField(
    key: ValueKey('mcp_catalog_field_${field.key}'),
    controller: owner._fields[field.key],
    decoration: _decoration(),
    obscureText: field.isSecret,
    onChanged: (_) => owner._fieldChanged(),
  );

  InputDecoration _decoration() => .new(
    labelText:
        '${field.label ?? field.key} '
        '${String.fromCharCode(_McpCatalogBrowserState._separatorCodePoint)} '
        '${_requiredLabel()}',
    helperText: field.description,
  );

  String _requiredLabel() =>
      (field.isRequired
              ? LocaleKeys.mcp_catalog_required
              : LocaleKeys.mcp_catalog_optional)
          .tr();
}

class const _McpCatalogFieldHelpLink({required final String url})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () =>
        unawaited(launchUrl(.parse(url), mode: .externalApplication)),
    child: Text(LocaleKeys.mcp_catalog_help.tr()),
  );
}

class const _McpCatalogDeviceCode({required final McpOAuthDeviceCode? code})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final deviceCode = code;
    if (deviceCode == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(LocaleKeys.mcp_modal_oauth_device_code_instructions.tr()),
        SelectableText(deviceCode.userCode),
        SelectableText(deviceCode.verificationUrl),
      ],
    );
  }
}

class const _McpCatalogFeedback({
  required final bool isBusy,
  required final int? toolCount,
  required final String? errorKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (isBusy) const Center(child: CircularProgressIndicator()),
      if (toolCount case final count?)
        Text(
          LocaleKeys.mcp_catalog_verification_success.tr(
            namedArgs: {'count': '$count'},
          ),
        ),
      if (errorKey case final key?) Text(key.tr()),
    ],
  );
}

bool _supportsTransport(String transport, WorkspaceCapabilities capabilities) =>
    capabilities.mcpTransports.any((value) => value.name == transport);

bool _supportsOption(String authType, WorkspaceCapabilities capabilities) =>
    capabilities.mcpAuthentication.any(
      (value) =>
          value.name == authType ||
          {'apiKey', 'httpHeaders'}.contains(authType) &&
              value == WorkspaceMcpAuthentication.httpHeaders,
    );
