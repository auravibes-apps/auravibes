import 'dart:async';

import 'package:auravibes_app/features/service_connections/models/mcp_catalog_installation.dart';
import 'package:auravibes_app/features/service_connections/providers/mcp_catalog_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/install_mcp_catalog_entry_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/mcp_service/mcp_oauth_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  final _search = TextEditingController();
  final _fields = <String, TextEditingController>{};
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

  void _clearFields() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _fields.clear();
  }

  void _discardVerification() {
    final id = _verificationId;
    _verificationId = null;
    if (id != null) {
      unawaited(
        ref
            .read(mcpConnectionProvider.notifier)
            .discardPreparedMcpConnection(id),
      );
    }
  }

  void _select(McpCatalogListing listing, McpCatalogConnectionOption option) {
    _discardVerification();
    _clearFields();
    for (final field in option.fields) {
      _fields[field.key] = TextEditingController();
    }
    setState(() {
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
    setState(() {
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

  InstallMcpCatalogEntryUseCase get _installUseCase =>
      InstallMcpCatalogEntryUseCase(
        prepare: (form, workspaceId) => ref
            .read(mcpConnectionProvider.notifier)
            .prepareMcpConnection(
              form,
              workspaceId: workspaceId,
              onOAuthDeviceCode: (code) {
                if (mounted) setState(() => _deviceCode = code);
              },
            ),
        commit: (form, workspaceId, verificationId) => ref
            .read(mcpConnectionProvider.notifier)
            .commitPreparedMcpConnection(
              form,
              workspaceId: workspaceId,
              verificationId: verificationId,
            ),
      );

  Future<void> _verify() async {
    final request = _request();
    if (request == null || _busy) return;
    if (request.missingRequiredFields.isNotEmpty) {
      setState(() => _errorKey = LocaleKeys.mcp_catalog_missing_fields);
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
      _toolCount = null;
    });
    try {
      final verification = await _installUseCase.verify(request);
      if (!mounted) return;
      setState(() {
        _verificationId = verification.id;
        _toolCount = verification.toolCount;
      });
    } on Object {
      if (mounted) {
        setState(() => _errorKey = LocaleKeys.mcp_catalog_verification_error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _install() async {
    final request = _request();
    final verificationId = _verificationId;
    if (request == null || verificationId == null || _busy) return;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await _installUseCase.install(request, verificationId);
      if (!mounted) return;
      _verificationId = null;
      ref.invalidate(serviceConnectionsProvider(widget.workspaceId));
      Navigator.of(context).pop(true);
    } on Object {
      if (mounted) {
        setState(() => _errorKey = LocaleKeys.mcp_catalog_install_error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;
    final option = _option;
    return AlertDialog(
      title: Text(LocaleKeys.mcp_catalog_title.tr()),
      content: SizedBox(
        width: 520,
        height: 560,
        child: listing == null || option == null
            ? _browseContent()
            : _configureContent(listing, option),
      ),
      actions: [
        if (listing != null)
          TextButton(
            onPressed: _busy ? null : _back,
            child: Text(LocaleKeys.mcp_catalog_back.tr()),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        if (listing != null) ...[
          OutlinedButton(
            onPressed: _busy ? null : _verify,
            child: Text(LocaleKeys.mcp_catalog_verify.tr()),
          ),
          FilledButton(
            onPressed: _busy || _verificationId == null ? null : _install,
            child: Text(LocaleKeys.mcp_catalog_install.tr()),
          ),
        ],
      ],
    );
  }

  Widget _browseContent() {
    final listings = ref.watch(mcpCatalogProvider(widget.workspaceId));
    final session = ref.watch(
      workspaceSessionForRouteProvider(widget.workspaceId),
    );
    if (listings.isLoading || session.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (listings.hasError || session.hasError) {
      final key = listings.error is McpCatalogSignInRequired
          ? LocaleKeys.mcp_catalog_sign_in_required
          : LocaleKeys.mcp_catalog_load_error;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(key.tr()),
            TextButton(
              onPressed: () =>
                  ref.invalidate(mcpCatalogProvider(widget.workspaceId)),
              child: Text(LocaleKeys.common_reload.tr()),
            ),
          ],
        ),
      );
    }
    final capabilities = session.requireValue.capabilities;
    final available = listings.requireValue;
    final filtered = filterMcpCatalog(
      available,
      query: _search.text,
      transport: _transport,
      authType: _authType,
    );
    return Column(
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: LocaleKeys.mcp_catalog_search.tr(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        Row(
          children: [
            Expanded(
              child: _filter(
                LocaleKeys.mcp_catalog_transport,
                _transport,
                const ['streamableHttp', 'sse'],
                (value) => setState(() => _transport = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filter(
                LocaleKeys.mcp_catalog_authentication,
                _authType,
                const ['none', 'oauth', 'bearerToken', 'apiKey', 'httpHeaders'],
                (value) => setState(() => _authType = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    (available.isEmpty
                            ? LocaleKeys.mcp_catalog_empty
                            : LocaleKeys.mcp_catalog_no_match)
                        .tr(),
                  ),
                )
              : ListView(
                  children: [
                    for (final entry in filtered)
                      for (final choice in entry.options)
                        if (_authType == null || choice.authType == _authType)
                          _choiceTile(entry, choice, capabilities),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _choiceTile(
    McpCatalogListing listing,
    McpCatalogConnectionOption option,
    WorkspaceCapabilities capabilities,
  ) {
    final supported =
        _supportsTransport(listing.transport, capabilities) &&
        _supportsOption(option.authType, capabilities);
    final unavailable = supported
        ? ''
        : '\n${LocaleKeys.mcp_catalog_unsupported_option.tr()}';
    return ListTile(
      title: Text('${listing.name} · ${option.name}'),
      subtitle: Text(
        '${listing.description}\n${listing.transport}$unavailable',
      ),
      isThreeLine: true,
      onTap: supported ? () => _select(listing, option) : null,
    );
  }

  Widget _filter(
    String labelKey,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String?>(
    initialValue: value,
    decoration: InputDecoration(labelText: labelKey.tr()),
    items: [
      DropdownMenuItem(child: Text(LocaleKeys.mcp_catalog_all.tr())),
      for (final option in options)
        DropdownMenuItem(value: option, child: Text(option)),
    ],
    onChanged: onChanged,
  );

  Widget _configureContent(
    McpCatalogListing listing,
    McpCatalogConnectionOption option,
  ) => ListView(
    children: [
      Text(
        '${listing.name} · ${option.name}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(listing.description),
      const SizedBox(height: 12),
      for (final field in option.fields) _fieldInput(field),
      if (_deviceCode case final code?) ...[
        Text(LocaleKeys.mcp_modal_oauth_device_code_instructions.tr()),
        SelectableText(code.userCode),
        SelectableText(code.verificationUrl),
      ],
      if (_busy) const Center(child: CircularProgressIndicator()),
      if (_toolCount case final count?)
        Text(
          LocaleKeys.mcp_catalog_verification_success.tr(
            namedArgs: {'count': '$count'},
          ),
        ),
      if (_errorKey case final key?) Text(key.tr()),
    ],
  );

  Widget _fieldInput(McpCatalogCredentialField field) {
    final label = field.label ?? field.key;
    final requirement =
        (field.isRequired
                ? LocaleKeys.mcp_catalog_required
                : LocaleKeys.mcp_catalog_optional)
            .tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: ValueKey('mcp_catalog_field_${field.key}'),
          controller: _fields[field.key],
          obscureText: field.isSecret,
          decoration: InputDecoration(
            labelText: '$label · $requirement',
            helperText: field.description,
          ),
          onChanged: (_) {
            _discardVerification();
            setState(() {
              _toolCount = null;
              _errorKey = null;
            });
          },
        ),
        if (field.helpUrl case final url?)
          TextButton(
            onPressed: () => unawaited(
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
            child: Text(LocaleKeys.mcp_catalog_help.tr()),
          ),
      ],
    );
  }
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
