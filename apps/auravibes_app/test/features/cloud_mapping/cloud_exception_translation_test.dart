import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  test('translates every workspace error code', () {
    for (final code in CloudWorkspaceErrorCode.values) {
      final error = _translate(
        CloudWorkspaceException(code: code),
        .workspace,
      );
      expect(error.code, code.name);
      expect(error.localizationKey, isNotEmpty);
    }
  });

  test('translates every conversation error code', () {
    for (final code in ConversationErrorCode.values) {
      final error = _translate(
        ConversationException(code: code),
        .conversation,
      );
      expect(error.code, code.name);
      expect(error.localizationKey, isNotEmpty);
    }
  });

  test('translates every object error code', () {
    for (final code in ObjectErrorCode.values) {
      final error = _translate(ObjectException(code: code), .object);
      expect(error.code, code.name);
      expect(error.localizationKey, isNotEmpty);
    }
  });

  test('translates state, MCP, model, OAuth and runtime failures', () {
    for (final context in const [
      CloudOperationContext.state,
      CloudOperationContext.mcp,
      CloudOperationContext.model,
      CloudOperationContext.oauth,
    ]) {
      final error = _translate(StateError('unsafe text'), context);
      expect(error.context, context);
      expect(error.localizationKey, LocaleKeys.cloud_errors_malformed_resource);
      expect(error.toString(), isNot(contains('unsafe text')));
    }
    for (final error in <Object>[
      const FormatException('unsafe text'),
      UnsupportedError('unsafe text'),
      const UnsupportedWorkspaceCapabilityException(),
    ]) {
      expect(_translate(error, .resource).localizationKey, isNotEmpty);
    }
  });

  test('logs untranslatable cloud failures before mapping them', () async {
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    final error = StateError('request failed');

    await expectLater(
      CloudAppErrors.guardCall<void>(.state, () => Future<void>.error(error)),
      throwsA(isA<CloudAppException>()),
    );
    await subscription.cancel();

    expect(
      records.where((record) => record.loggerName == 'cloud_app_exception'),
      contains(
        isA<LogRecord>()
            .having((record) => record.level, 'level', Level.SEVERE)
            .having((record) => record.error, 'error', error)
            .having((record) => record.stackTrace, 'stackTrace', isNotNull),
      ),
    );
  });
}

CloudAppException _translate(Object error, CloudOperationContext context) {
  try {
    CloudAppErrors.translateException(error, context);
  } on CloudAppException catch (translated) {
    return translated;
  }
}
