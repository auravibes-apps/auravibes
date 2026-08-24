import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateWorkspaceScreen extends StatelessWidget {
  const CreateWorkspaceScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final createLocation = WorkspaceCreateRoute(
      workspaceId: workspaceId,
    ).location;

    return AuraScreen(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CreateWorkspaceForm(
            onCreated: (workspace) => context.go(
              NewChatRoute(workspaceId: workspace.id).location,
            ),
            onAddCloudAccount: () => context.go(
              CloudAccountAddRoute(
                workspaceId: workspaceId,
                returnPath: createLocation,
              ).location,
            ),
          ),
        ],
      ),
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.workspace_management_create_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class CreateWorkspaceForm extends ConsumerStatefulWidget {
  const CreateWorkspaceForm({
    required this.onCreated,
    this.onAddCloudAccount,
    super.key,
  });

  final ValueChanged<WorkspaceEntity> onCreated;
  final VoidCallback? onAddCloudAccount;

  @override
  ConsumerState<CreateWorkspaceForm> createState() =>
      _CreateWorkspaceFormState();
}

class _CreateWorkspaceFormState extends ConsumerState<CreateWorkspaceForm> {
  static const _localTarget = '';

  final _name = TextEditingController();
  String _targetAccountId = _localTarget;
  bool _isCreating = false;
  String? _errorText;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(cloudAccountsProvider);

    if (accounts case AsyncData(:final value)) {
      final errorText = _errorText;

      return AuraColumn(
        children: [
          AuraInput(
            controller: _name,
            placeholder: Text(
              LocaleKeys.workspace_management_name_placeholder.tr(),
            ),
            label: Text(LocaleKeys.workspace_management_name_label.tr()),
            error: errorText == null ? null : Text(errorText),
            state: errorText == null
                ? AuraInputState.normal
                : AuraInputState.error,
            textInputAction: TextInputAction.done,
            enabled: !_isCreating,
            onSubmitted: (_) => unawaited(_create()),
          ),
          AuraDropdownSelector<String>(
            options: [
              const AuraDropdownOption(
                value: _localTarget,
                child: TextLocale('workspace_management.local_target'),
              ),
              for (final account in value)
                AuraDropdownOption(
                  value: account.userId,
                  child: Text(account.email),
                ),
            ],
            value: _targetAccountId,
            onChanged: (accountId) {
              if (accountId != null) {
                setState(() => _targetAccountId = accountId);
              }
            },
            label: const TextLocale('workspace_management.target_label'),
            isEnabled: !_isCreating,
          ),
          if (value.isEmpty)
            if (widget.onAddCloudAccount case final onAddCloudAccount?)
              AuraButton(
                onPressed: onAddCloudAccount,
                child: const TextLocale(LocaleKeys.cloud_accounts_add),
                variant: AuraButtonVariant.outlined,
              )
            else
              const TextLocale('workspace_management.cloud_add_hint'),
          AuraButton(
            onPressed: () => unawaited(_create()),
            child: const TextLocale(
              LocaleKeys.workspace_management_create_button,
            ),
            key: const Key('intro_create_workspace_button'),
            isLoading: _isCreating,
            disabled: _isCreating,
          ),
        ],
        spacing: .md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
      );
    }

    return switch (accounts) {
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => const Center(
        child: TextLocale(LocaleKeys.cloud_accounts_load_error),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _create() async {
    if (_isCreating) return;

    final name = _name.text.trim();
    setState(() {
      _isCreating = true;
      _errorText = null;
    });

    try {
      ref.read(validateWorkspaceNameUseCaseProvider).call(name: name);
      final workspace = await _createWorkspace(name);
      ref.invalidate(allWorkspacesProvider);
      if (_targetAccountId != _localTarget) {
        ref.invalidate(cloudWorkspaceStateProvider(_targetAccountId));
      }
      if (mounted) widget.onCreated(workspace);
    } on AppCloudWorkspaceException catch (error) {
      if (mounted) setState(() => _errorText = error.localizationKey.tr());
    } on WorkspaceException catch (error) {
      if (mounted) setState(() => _errorText = _workspaceError(error));
    } on Object catch (error, stackTrace) {
      debugPrint('Create workspace failed: $error\n$stackTrace');
      if (mounted) {
        setState(
          () => _errorText = LocaleKeys.workspace_management_unexpected_error
              .tr(),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<WorkspaceEntity> _createWorkspace(String name) async {
    if (_targetAccountId == _localTarget) {
      return ref.read(createWorkspaceUseCaseProvider).call(name: name);
    }

    final useCases = await ref.read(
      cloudWorkspaceUseCasesProvider(_targetAccountId).future,
    );
    if (useCases == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      );
    }

    return useCases.create(name);
  }

  String _workspaceError(WorkspaceException error) {
    final key = error.localizationKey;
    if (key == null) return error.message;

    return key.tr(
      namedArgs: {
        'min': '${ValidateWorkspaceNameUseCase.minLength}',
        'max': '${ValidateWorkspaceNameUseCase.maxLength}',
      },
    );
  }
}
