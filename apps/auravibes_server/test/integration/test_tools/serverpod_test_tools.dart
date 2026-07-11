/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: no_leading_underscores_for_local_identifiers

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_test/serverpod_test.dart' as _i1;
import 'package:serverpod/serverpod.dart' as _i2;
import 'dart:io' as _i3;
import 'dart:async' as _i4;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i5;
import 'package:auravibes_server/src/generated/features/accounts/models/account_summary.dart'
    as _i6;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_summary.dart'
    as _i7;
import 'package:auravibes_server/src/generated/features/workspaces/models/pending_workspace_invite_summary.dart'
    as _i8;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_detail.dart'
    as _i9;
import 'package:auravibes_server/src/generated/features/workspaces/models/get_cloud_workspace_detail_request.dart'
    as _i10;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_member_summary.dart'
    as _i11;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_workspace_members_request.dart'
    as _i12;
import 'package:auravibes_server/src/generated/features/workspaces/models/cloud_workspace_invite_summary.dart'
    as _i13;
import 'package:auravibes_server/src/generated/features/workspaces/models/list_cloud_workspace_invites_request.dart'
    as _i14;
import 'package:auravibes_server/src/generated/features/workspaces/models/create_cloud_workspace_request.dart'
    as _i15;
import 'package:auravibes_server/src/generated/features/workspaces/models/invite_workspace_member_request.dart'
    as _i16;
import 'package:auravibes_server/src/generated/features/workspaces/models/renew_workspace_invite_request.dart'
    as _i17;
import 'package:auravibes_server/src/generated/features/workspaces/models/revoke_workspace_invite_request.dart'
    as _i18;
import 'package:auravibes_server/src/generated/features/workspaces/models/accept_workspace_invite_request.dart'
    as _i19;
import 'package:auravibes_server/src/generated/features/workspaces/models/decline_workspace_invite_request.dart'
    as _i20;
import 'package:auravibes_server/src/generated/features/workspaces/models/rename_cloud_workspace_request.dart'
    as _i21;
import 'package:auravibes_server/src/generated/features/workspaces/models/leave_cloud_workspace_request.dart'
    as _i22;
import 'package:auravibes_server/src/generated/features/workspaces/models/transfer_cloud_workspace_ownership_request.dart'
    as _i23;
import 'package:auravibes_server/src/generated/features/workspaces/models/update_workspace_member_role_request.dart'
    as _i24;
import 'package:auravibes_server/src/generated/features/workspaces/models/remove_workspace_member_request.dart'
    as _i25;
import 'package:auravibes_server/src/generated/features/workspaces/models/delete_cloud_workspace_request.dart'
    as _i26;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:auravibes_server/src/generated/endpoints.dart';
export 'package:serverpod_test/serverpod_test_public_exports.dart';

/// Creates a new test group that takes a callback that can be used to write tests.
/// The callback has two parameters: `sessionBuilder` and `endpoints`.
/// `sessionBuilder` is used to build a `Session` object that represents the server state during an endpoint call and is used to set up scenarios.
/// `endpoints` contains all your Serverpod endpoints and lets you call them:
/// ```dart
/// withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
///   test('when calling `hello` then should return greeting', () async {
///     final greeting = await endpoints.example.hello(sessionBuilder, 'Michael');
///     expect(greeting, 'Hello Michael');
///   });
/// });
/// ```
///
/// **Configuration options**
///
/// [applyMigrations] Whether pending migrations should be applied when starting Serverpod. Defaults to `true`
///
/// [enableSessionLogging] Whether session logging should be enabled. Defaults to `false`
///
/// [rollbackDatabase] Options for when to rollback the database during the test lifecycle.
/// By default `withServerpod` does all database operations inside a transaction that is rolled back after each `test` case.
/// Just like the following enum describes, the behavior of the automatic rollbacks can be configured:
/// ```dart
/// /// Options for when to rollback the database during the test lifecycle.
/// enum RollbackDatabase {
///   /// After each test. This is the default.
///   afterEach,
///
///   /// After all tests.
///   afterAll,
///
///   /// Disable rolling back the database.
///   disabled,
/// }
/// ```
///
/// [runMode] The run mode that Serverpod should be running in. Defaults to `test`.
///
/// [serverpodLoggingMode] The logging mode used when creating Serverpod. Defaults to `ServerpodLoggingMode.normal`
///
/// [serverpodStartTimeout] The timeout to use when starting Serverpod, which connects to the database among other things. Defaults to `Duration(seconds: 30)`.
///
/// [testServerOutputMode] Options for controlling test server output during test execution. Defaults to `TestServerOutputMode.normal`.
/// ```dart
/// /// Options for controlling test server output during test execution.
/// enum TestServerOutputMode {
///   /// Default mode - only stderr is printed (stdout suppressed).
///   /// This hides normal startup/shutdown logs while preserving error messages.
///   normal,
///
///   /// All logging - both stdout and stderr are printed.
///   /// Useful for debugging when you need to see all server output.
///   verbose,
///
///   /// No logging - both stdout and stderr are suppressed.
///   /// Completely silent mode, useful when you don't want any server output.
///   silent,
/// }
/// ```
///
/// [configOverride] A function to override the server configuration. This function is called with
/// the default server configuration after it is loaded from the config/ directory
/// and before it is used to start the server. Use this to override particular
/// settings in the server configuration.
///
/// [testGroupTagsOverride] By default Serverpod test tools tags the `withServerpod` test group with `"integration"`.
/// This is to provide a simple way to only run unit or integration tests.
/// This property allows this tag to be overridden to something else. Defaults to `['integration']`.
///
/// [experimentalFeatures] Optionally specify experimental features. See [Serverpod] for more information.
///
/// [serverDirectory] The server package directory `config/<runMode>.yaml`, `config/passwords.yaml`,
/// and `migrations/<module>/...` are resolved against. Defaults to
/// [Directory.current] at the time the test boots. Pass this when the test
/// isolate's cwd is not the server package root (e.g. running tests from a
/// workspace parent directory) so config and migrations are still loaded
/// from the right place.
@_i1.isTestGroup
void withServerpod(
  String testGroupName,
  _i1.TestClosure<TestEndpoints> testClosure, {
  bool? applyMigrations,
  _i2.ServerpodConfig Function(_i2.ServerpodConfig)? configOverride,
  bool? enableSessionLogging,
  _i2.ExperimentalFeatures? experimentalFeatures,
  _i1.RollbackDatabase? rollbackDatabase,
  String? runMode,
  _i2.RuntimeParametersListBuilder? runtimeParametersBuilder,
  _i3.Directory? serverDirectory,
  _i2.ServerpodLoggingMode? serverpodLoggingMode,
  Duration? serverpodStartTimeout,
  List<String>? testGroupTagsOverride,
  _i1.TestServerOutputMode? testServerOutputMode,
}) {
  _i1.buildWithServerpod<_InternalTestEndpoints>(
    testGroupName,
    _i1.TestServerpod(
      testEndpoints: _InternalTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: runMode,
      applyMigrations: applyMigrations,
      isDatabaseEnabled: true,
      serverpodLoggingMode: serverpodLoggingMode,
      testServerOutputMode: testServerOutputMode,
      serverDirectory: serverDirectory,
      experimentalFeatures: experimentalFeatures,
      configOverride: configOverride,
      runtimeParametersBuilder: runtimeParametersBuilder,
    ),
    maybeRollbackDatabase: rollbackDatabase,
    maybeEnableSessionLogging: enableSessionLogging,
    maybeTestGroupTagsOverride: testGroupTagsOverride,
    maybeServerpodStartTimeout: serverpodStartTimeout,
    maybeTestServerOutputMode: testServerOutputMode,
  )(testClosure);
}

class TestEndpoints {
  late final _EmailIdpEndpoint emailIdp;

  late final _JwtRefreshEndpoint jwtRefresh;

  late final _AccountEndpoint account;

  late final _CloudWorkspaceEndpoint cloudWorkspace;
}

class _InternalTestEndpoints extends TestEndpoints
    implements _i1.InternalTestEndpoints {
  @override
  void initialize(
    _i2.SerializationManager serializationManager,
    _i2.EndpointDispatch endpoints,
  ) {
    emailIdp = _EmailIdpEndpoint(
      endpoints,
      serializationManager,
    );
    jwtRefresh = _JwtRefreshEndpoint(
      endpoints,
      serializationManager,
    );
    account = _AccountEndpoint(
      endpoints,
      serializationManager,
    );
    cloudWorkspace = _CloudWorkspaceEndpoint(
      endpoints,
      serializationManager,
    );
  }
}

class _EmailIdpEndpoint {
  _EmailIdpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i4.Future<_i5.AuthSuccess> login(
    _i1.TestSessionBuilder sessionBuilder, {
    required String email,
    required String password,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'login',
          parameters: _i1.testObjectToJson({
            'email': email,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i5.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i2.UuidValue> startRegistration(
    _i1.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startRegistration',
          parameters: _i1.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i2.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<String> verifyRegistrationCode(
    _i1.TestSessionBuilder sessionBuilder, {
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyRegistrationCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyRegistrationCode',
          parameters: _i1.testObjectToJson({
            'accountRequestId': accountRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i5.AuthSuccess> finishRegistration(
    _i1.TestSessionBuilder sessionBuilder, {
    required String registrationToken,
    required String password,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishRegistration',
          parameters: _i1.testObjectToJson({
            'registrationToken': registrationToken,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i5.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i2.UuidValue> startPasswordReset(
    _i1.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startPasswordReset',
          parameters: _i1.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i2.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<String> verifyPasswordResetCode(
    _i1.TestSessionBuilder sessionBuilder, {
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyPasswordResetCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyPasswordResetCode',
          parameters: _i1.testObjectToJson({
            'passwordResetRequestId': passwordResetRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> finishPasswordReset(
    _i1.TestSessionBuilder sessionBuilder, {
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishPasswordReset',
          parameters: _i1.testObjectToJson({
            'finishPasswordResetToken': finishPasswordResetToken,
            'newPassword': newPassword,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<bool> hasAccount(_i1.TestSessionBuilder sessionBuilder) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'hasAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'hasAccount',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _JwtRefreshEndpoint {
  _JwtRefreshEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i4.Future<_i5.AuthSuccess> refreshAccessToken(
    _i1.TestSessionBuilder sessionBuilder, {
    required String refreshToken,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'jwtRefresh',
            method: 'refreshAccessToken',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'jwtRefresh',
          methodName: 'refreshAccessToken',
          parameters: _i1.testObjectToJson({'refreshToken': refreshToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i5.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AccountEndpoint {
  _AccountEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i4.Future<_i6.AccountSummary> currentUser(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'account',
            method: 'currentUser',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'account',
          methodName: 'currentUser',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i6.AccountSummary>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _CloudWorkspaceEndpoint {
  _CloudWorkspaceEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i4.Future<List<_i7.CloudWorkspaceSummary>> listAuthorizedWorkspaces(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'listAuthorizedWorkspaces',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'listAuthorizedWorkspaces',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<List<_i7.CloudWorkspaceSummary>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<List<_i8.PendingWorkspaceInviteSummary>> listPendingInvites(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'listPendingInvites',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'listPendingInvites',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<List<_i8.PendingWorkspaceInviteSummary>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i9.CloudWorkspaceDetail> getWorkspaceDetail(
    _i1.TestSessionBuilder sessionBuilder,
    _i10.GetCloudWorkspaceDetailRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'getWorkspaceDetail',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'getWorkspaceDetail',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i9.CloudWorkspaceDetail>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<List<_i11.CloudWorkspaceMemberSummary>> listMembers(
    _i1.TestSessionBuilder sessionBuilder,
    _i12.ListWorkspaceMembersRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'listMembers',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'listMembers',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<List<_i11.CloudWorkspaceMemberSummary>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<List<_i13.CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    _i1.TestSessionBuilder sessionBuilder,
    _i14.ListCloudWorkspaceInvitesRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'listWorkspaceInvites',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'listWorkspaceInvites',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<List<_i13.CloudWorkspaceInviteSummary>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i7.CloudWorkspaceSummary> createWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    _i15.CreateCloudWorkspaceRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'createWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'createWorkspace',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i7.CloudWorkspaceSummary>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i8.PendingWorkspaceInviteSummary> inviteMember(
    _i1.TestSessionBuilder sessionBuilder,
    _i16.InviteWorkspaceMemberRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'inviteMember',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'inviteMember',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i8.PendingWorkspaceInviteSummary>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i13.CloudWorkspaceInviteSummary> renewInvite(
    _i1.TestSessionBuilder sessionBuilder,
    _i17.RenewWorkspaceInviteRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'renewInvite',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'renewInvite',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i13.CloudWorkspaceInviteSummary>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> revokeInvite(
    _i1.TestSessionBuilder sessionBuilder,
    _i18.RevokeWorkspaceInviteRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'revokeInvite',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'revokeInvite',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i7.CloudWorkspaceSummary> acceptInvite(
    _i1.TestSessionBuilder sessionBuilder,
    _i19.AcceptWorkspaceInviteRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'acceptInvite',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'acceptInvite',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i7.CloudWorkspaceSummary>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> declineInvite(
    _i1.TestSessionBuilder sessionBuilder,
    _i20.DeclineWorkspaceInviteRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'declineInvite',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'declineInvite',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<_i7.CloudWorkspaceSummary> renameWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    _i21.RenameCloudWorkspaceRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'renameWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'renameWorkspace',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<_i7.CloudWorkspaceSummary>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> leaveWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    _i22.LeaveCloudWorkspaceRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'leaveWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'leaveWorkspace',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> transferOwnership(
    _i1.TestSessionBuilder sessionBuilder,
    _i23.TransferCloudWorkspaceOwnershipRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'transferOwnership',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'transferOwnership',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> updateMemberRole(
    _i1.TestSessionBuilder sessionBuilder,
    _i24.UpdateWorkspaceMemberRoleRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'updateMemberRole',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'updateMemberRole',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> removeMember(
    _i1.TestSessionBuilder sessionBuilder,
    _i25.RemoveWorkspaceMemberRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'removeMember',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'removeMember',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i4.Future<void> deleteWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    _i26.DeleteCloudWorkspaceRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'cloudWorkspace',
            method: 'deleteWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'cloudWorkspace',
          methodName: 'deleteWorkspace',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i4.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}
