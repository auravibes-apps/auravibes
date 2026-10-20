import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/features/chats/models/mcp_elicitation_form.dart';
import 'package:auravibes_app/features/chats/notifiers/mcp_elicitation_notifier.dart';
import 'package:auravibes_app/features/chats/usecases/mcp_elicitation_form_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/open_mcp_elicitation_url_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ChatMcpElicitationCard({
  required final String conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(mcpElicitationProvider(conversationId));
    if (requests.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      children: [
        for (final request in requests)
          Padding(
            key: ValueKey(request.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: _McpElicitationRequestCard(
              conversationId: conversationId,
              pending: request,
            ),
          ),
      ],
    );
  }
}

class const _McpElicitationRequestCard({
  required final String conversationId,
  required final McpElicitationPending pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (pending.request.mode) {
    .form => _McpElicitationFormCard(
      conversationId: conversationId,
      pending: pending,
    ),
    .url => _McpElicitationUrlCard(
      conversationId: conversationId,
      pending: pending,
    ),
    .unsupported => _McpElicitationUnsupportedCard(
      conversationId: conversationId,
      pending: pending,
    ),
  };
}

class const _McpElicitationFormCard({
  required final String conversationId,
  required final McpElicitationPending pending,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _McpElicitationFormCardContent(
      conversationId: conversationId,
      pending: pending,
      state: _useMcpElicitationFormCardState(ref, pending),
    );
  }
}

typedef _McpElicitationFormCardState = ({
  McpElicitationFormUsecase usecase,
  McpElicitationForm? form,
  ValueNotifier<Map<String, Object?>> values,
  ValueNotifier<McpElicitationFormValidationException?> validationError,
});

_McpElicitationFormCardState _useMcpElicitationFormCardState(
  WidgetRef ref,
  McpElicitationPending pending,
) {
  final usecase = ref.watch(mcpElicitationFormUsecaseProvider);
  final form = _useMcpElicitationForm(pending, usecase);

  return (
    usecase: usecase,
    form: form,
    values: _useMcpElicitationFormValues(pending.id, form),
    validationError: useState<McpElicitationFormValidationException?>(null),
  );
}

McpElicitationForm? _useMcpElicitationForm(
  McpElicitationPending pending,
  McpElicitationFormUsecase usecase,
) => useMemoized(() => usecase.parse(pending.request.requestedSchema), [
  pending.id,
  usecase,
]);

ValueNotifier<Map<String, Object?>> _useMcpElicitationFormValues(
  String requestId,
  McpElicitationForm? form,
) {
  final initialValues = useMemoized(
    () => form?.initialValues() ?? <String, Object?>{},
    [requestId, form],
  );

  return useState(initialValues);
}

class const _McpElicitationFormCardContent({
  required final String conversationId,
  required final McpElicitationPending pending,
  required final _McpElicitationFormCardState state,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responder = _McpElicitationCardResponder(
      ref: ref,
      conversationId: conversationId,
      requestId: pending.id,
    );

    return _McpElicitationCardFrame(
      request: pending.request,
      content: _McpElicitationFormCardBody(state: state),
      onDecline: responder.decline,
      onCancel: responder.cancel,
      primaryAction: _McpElicitationFormSubmitButton(
        conversationId: conversationId,
        pending: pending,
        state: state,
      ),
    );
  }
}

final class _McpElicitationCardResponder({
  required final WidgetRef ref,
  required final String conversationId,
  required final String requestId,
}) {
  void decline() => _respond(ref, conversationId, requestId, .decline);

  void cancel() => _respond(ref, conversationId, requestId, .cancel);
}

class const _McpElicitationFormCardBody({
  required final _McpElicitationFormCardState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _McpElicitationFormFields(
        form: state.form,
        values: state.values.value,
        onChanged: (name, value) => _updateFormValue(state, name, value),
      ),
      _McpElicitationFormValidationNotice(error: state.validationError.value),
    ],
  );
}

class const _McpElicitationFormSubmitButton({
  required final String conversationId,
  required final McpElicitationPending pending,
  required final _McpElicitationFormCardState state,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => _submitMcpElicitationForm((
      ref: ref,
      conversationId: conversationId,
      pending: pending,
      state: state,
    )),
    child: const TextLocale(LocaleKeys.mcp_elicitation_submit),
    disabled: state.form == null,
    identifier: 'mcp_elicitation_submit',
  );
}

void _updateFormValue(
  _McpElicitationFormCardState state,
  String name,
  Object? value,
) {
  state.values.value = {...state.values.value, name: value};
  state.validationError.value = null;
}

typedef _McpElicitationFormSubmission = ({
  WidgetRef ref,
  String conversationId,
  McpElicitationPending pending,
  _McpElicitationFormCardState state,
});

void _submitMcpElicitationForm(_McpElicitationFormSubmission submission) {
  final state = submission.state;
  try {
    final content = _validatedFormContent(state);
    if (content == null) return;
    _respondToForm(submission, content);
  } on McpElicitationFormValidationException catch (error) {
    state.validationError.value = error;
  }
}

Map<String, Object?>? _validatedFormContent(
  _McpElicitationFormCardState state,
) {
  final form = state.form;
  if (form == null) return null;

  return state.usecase.validate(form, state.values.value);
}

void _respondToForm(
  _McpElicitationFormSubmission submission,
  Map<String, Object?> content,
) {
  submission.ref
      .read(mcpElicitationProvider(submission.conversationId).notifier)
      .respond(
        requestId: submission.pending.id,
        response: .new(action: .accept, content: content),
      );
}

class const _McpElicitationUrlCard({
  required final String conversationId,
  required final McpElicitationPending pending,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpening = useState(false);
    final openError = useState<McpElicitationUrlOpenException?>(null);
    final openController = _McpElicitationUrlOpenController(
      context: context,
      ref: ref,
      conversationId: conversationId,
      pending: pending,
      isOpening: isOpening,
      openError: openError,
    );

    return _McpElicitationUrlCardContent(
      pending: pending,
      details: openController.details,
      isOpening: isOpening,
      openError: openError,
      openController: openController,
    );
  }
}

class const _McpElicitationUrlCardContent({
  required final McpElicitationPending pending,
  required final _McpElicitationUrlSummary details,
  required final ValueNotifier<bool> isOpening,
  required final ValueNotifier<McpElicitationUrlOpenException?> openError,
  required final _McpElicitationUrlOpenController openController,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _McpElicitationCardFrame(
      request: pending.request,
      content: _McpElicitationUrlDetails(
        request: pending.request,
        details: details,
        openError: openError.value,
      ),
      onDecline: openController.decline,
      onCancel: openController.cancel,
      primaryAction: _McpElicitationOpenUrlButton(
        controller: openController,
        details: details,
        isOpening: isOpening,
      ),
    );
  }
}

final class _McpElicitationUrlOpenController({
  required final BuildContext context,
  required final WidgetRef ref,
  required final String conversationId,
  required final McpElicitationPending pending,
  required final ValueNotifier<bool> isOpening,
  required final ValueNotifier<McpElicitationUrlOpenException?> openError,
}) {
  _McpElicitationUrlSummary get details =>
      _McpElicitationUrlSafety.inspect(pending.request);

  McpElicitationNotifier get _notifier =>
      ref.read(mcpElicitationProvider(conversationId).notifier);

  void open() => unawaited(_open());

  void decline() => _respond(ref, conversationId, pending.id, .decline);

  void cancel() => _respond(ref, conversationId, pending.id, .cancel);

  Future<void> _open() async {
    final urlDetails = details;
    final target = urlDetails.uri;
    if (target == null ||
        urlDetails.host.verificationError ||
        isOpening.value) {
      return;
    }
    final notifier = _notifier;
    isOpening.value = true;
    openError.value = null;
    if (await _tryOpen(target)) _accept(notifier);
  }

  void _accept(McpElicitationNotifier notifier) {
    notifier.respond(
      requestId: pending.id,
      response: const .new(action: .accept),
    );
  }

  Future<bool> _tryOpen(Uri target) async {
    try {
      await ref.read(openMcpElicitationUrlUsecaseProvider).call(target);

      return true;
    } on McpElicitationUrlOpenException catch (error) {
      if (context.mounted) openError.value = error;

      return false;
    } finally {
      if (context.mounted) isOpening.value = false;
    }
  }
}

class const _McpElicitationOpenUrlButton({
  required final _McpElicitationUrlOpenController controller,
  required final _McpElicitationUrlSummary details,
  required final ValueNotifier<bool> isOpening,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: controller.open,
    child: const TextLocale(LocaleKeys.mcp_elicitation_open_url),
    isLoading: isOpening.value,
    disabled:
        details.uri == null ||
        details.host.verificationError ||
        isOpening.value,
    identifier: 'mcp_elicitation_open_url',
  );
}

class const _McpElicitationUnsupportedCard({
  required final String conversationId,
  required final McpElicitationPending pending,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = pending.request;

    return _McpElicitationCardFrame(
      request: request,
      content: const TextLocale(LocaleKeys.mcp_elicitation_unsupported_mode),
      onDecline: () => _respond(ref, conversationId, pending.id, .decline),
      onCancel: () => _respond(ref, conversationId, pending.id, .cancel),
    );
  }
}

class const _McpElicitationCardFrame({
  required final McpElicitationRequest request,
  required final Widget content,
  required final VoidCallback onDecline,
  required final VoidCallback onCancel,
  final Widget? primaryAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _McpElicitationCardHeading(request: request),
        const SizedBox(height: 8),
        content,
        const SizedBox(height: 12),
        _McpElicitationCardActions(
          primaryAction: primaryAction,
          onDecline: onDecline,
          onCancel: onCancel,
        ),
      ],
    ),
  );
}

class const _McpElicitationCardHeading({
  required final McpElicitationRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      TextLocale(_titleKey(request.mode), args: [request.serverName]),
      if (request.message.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(request.message),
      ],
    ],
  );

  String _titleKey(McpElicitationMode mode) => switch (mode) {
    .form => LocaleKeys.mcp_elicitation_form_title,
    .url => LocaleKeys.mcp_elicitation_url_title,
    .unsupported => LocaleKeys.mcp_elicitation_unsupported_title,
  };
}

class const _McpElicitationCardActions({
  required final Widget? primaryAction,
  required final VoidCallback onDecline,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _spacing,
    runSpacing: _spacing,
    children: [
      ?primaryAction,
      AuraButton(
        onPressed: onDecline,
        child: const TextLocale(LocaleKeys.mcp_elicitation_decline),
        variant: .outlined,
        identifier: 'mcp_elicitation_decline',
      ),
      AuraButton(
        onPressed: onCancel,
        child: const TextLocale(LocaleKeys.mcp_elicitation_cancel),
        variant: .text,
        identifier: 'mcp_elicitation_cancel',
      ),
    ],
  );
}

class const _McpElicitationFormFields({
  required final McpElicitationForm? form,
  required final Map<String, Object?> values,
  required final void Function(String, Object?) onChanged,
}) extends StatelessWidget {
  static const _viewportHeightFactor = 0.35;

  @override
  Widget build(BuildContext context) {
    final currentForm = form;
    if (currentForm == null) {
      return const TextLocale(LocaleKeys.mcp_elicitation_unsupported_fields);
    }

    return ConstrainedBox(
      constraints: .new(
        maxHeight: MediaQuery.sizeOf(context).height * _viewportHeightFactor,
      ),
      child: SingleChildScrollView(
        child: _McpElicitationFormFieldList(
          form: currentForm,
          values: values,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class const _McpElicitationFormFieldList({
  required final McpElicitationForm form,
  required final Map<String, Object?> values,
  required final void Function(String, Object?) onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      for (final entry in form.properties.entries)
        _McpElicitationFormFieldRow(
          form: form,
          entry: entry,
          values: values,
          onChanged: onChanged,
        ),
    ],
  );
}

class const _McpElicitationFormFieldRow({
  required final McpElicitationForm form,
  required final MapEntry<String, Map<String, Object?>> entry,
  required final Map<String, Object?> values,
  required final void Function(String, Object?) onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: _McpElicitationField(
      data: (
        info: _mcpElicitationFieldInfo(
          entry.key,
          entry.value,
          form.isRequired(entry.key),
        ),
        value: values[entry.key],
        onChanged: (value) => onChanged(entry.key, value),
      ),
    ),
  );
}

class const _McpElicitationUrlDetails({
  required final McpElicitationRequest request,
  required final _McpElicitationUrlSummary details,
  required final McpElicitationUrlOpenException? openError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _McpElicitationUrlTarget(request: request, details: details),
      _McpElicitationIntlHostNotice(details: details),
      _McpElicitationUrlValidationNotice(details: details),
      _McpElicitationUrlOpenFailure(error: openError),
      const SizedBox(height: 8),
      const TextLocale(LocaleKeys.mcp_elicitation_url_review),
    ],
  );
}

class const _McpElicitationUrlTarget({
  required final McpElicitationRequest request,
  required final _McpElicitationUrlSummary details,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      TextLocale(
        LocaleKeys.mcp_elicitation_url_host,
        args: [details.host.host ?? details.uri?.host ?? ''],
      ),
      const SizedBox(height: 4),
      SelectableText(request.url ?? ''),
    ],
  );
}

class const _McpElicitationUrlOpenFailure({
  required final McpElicitationUrlOpenException? error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (error) {
    final value? => Column(
      crossAxisAlignment: .start,
      children: [const SizedBox(height: 8), TextLocale(value.localizationKey)],
    ),
    null => const SizedBox.shrink(),
  };
}

class const _McpElicitationFormValidationNotice({
  required final McpElicitationFormValidationException? error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (error) {
    final value? => Column(
      crossAxisAlignment: .start,
      children: [const SizedBox(height: 8), TextLocale(value.localizationKey)],
    ),
    null => const SizedBox.shrink(),
  };
}

class const _McpElicitationIntlHostNotice({
  required final _McpElicitationUrlSummary details,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (details.host.isInternationalized) ...[
        const SizedBox(height: 8),
        const TextLocale(LocaleKeys.mcp_elicitation_url_punycode_warning),
        if (details.host.asciiHost case final String value)
          TextLocale(LocaleKeys.mcp_elicitation_url_ascii_host, args: [value]),
      ],
    ],
  );
}

class const _McpElicitationUrlValidationNotice({
  required final _McpElicitationUrlSummary details,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (details.uri == null) ...[
        const SizedBox(height: 8),
        const TextLocale(LocaleKeys.mcp_elicitation_invalid_url),
      ],
      if (details.host.verificationError) ...[
        const SizedBox(height: 8),
        const TextLocale(LocaleKeys.mcp_elicitation_url_ascii_host_error),
      ],
    ],
  );
}

final class const _McpElicitationField({
  required final _McpElicitationFieldData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final info = data.info;

    return switch (info.kind) {
      .enumeration => _McpElicitationEnumField(
        data: data,
        options: .new(info.enumValues ?? [], info.schema),
      ),
      .boolean => _McpElicitationBooleanField(data: data),
      .text => _McpElicitationTextField(
        settings: .new(
          info: info,
          value: data.value,
          onValueChanged: data.onChanged,
        ),
      ),
    };
  }
}

enum _McpElicitationFieldKind { enumeration, boolean, text }

typedef _McpElicitationFieldInfo = ({
  String name,
  Map<String, Object?> schema,
  bool isRequired,
  String label,
  String? description,
  List<Object?>? enumValues,
  _McpElicitationFieldKind kind,
});

_McpElicitationFieldInfo _mcpElicitationFieldInfo(
  String name,
  Map<String, Object?> schema,
  bool isRequired,
) {
  final enumValues = _objectList(schema['enum']);

  return (
    name: name,
    schema: schema,
    isRequired: isRequired,
    label: _stringValue(schema['title']) ?? name,
    description: _stringValue(schema['description']),
    enumValues: enumValues,
    kind: switch ((isEnum: enumValues != null, type: schema['type'])) {
      (isEnum: true, type: _) => .enumeration,
      (isEnum: false, type: 'boolean') => .boolean,
      _ => .text,
    },
  );
}

typedef _McpElicitationFieldData = ({
  _McpElicitationFieldInfo info,
  McpElicitationFieldValue value,
  ValueChanged<McpElicitationFieldValue> onChanged,
});

String? _stringValue(Object? value) => value is String ? value : null;

List<Object?>? _objectList(Object? value) =>
    value is List<Object?> ? value : null;

class const _McpElicitationEnumField({
  required final _McpElicitationFieldData data,
  required final _McpElicitationEnumOptions options,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<Object?>(
    options: options.options,
    value: data.value,
    onChanged: data.onChanged,
    placeholder: const TextLocale(LocaleKeys.mcp_elicitation_select_option),
    label: Text(data.info.label),
    isRequired: data.info.isRequired,
  );
}

final class _McpElicitationEnumOptions(
  final List<Object?> values,
  final Map<String, Object?> schema,
) {
  final List<AuraDropdownOption<Object?>> options = [
    for (final value in values)
      AuraDropdownOption<Object?>(
        value: value,
        child: Text(_enumOptionLabel(schema, value)),
      ),
  ];
}

class const _McpElicitationBooleanField({
  required final _McpElicitationFieldData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final info = data.info;
    final value = data.value;
    final onChanged = data.onChanged;

    return AuraCheckboxListTile(
      value: value == true,
      onChanged: onChanged,
      title: Text(info.label),
      subtitle: switch (info.description) {
        final String text => Text(text),
        null => null,
      },
      semanticLabel: info.label,
    );
  }
}

class const _McpElicitationTextField({
  required final _McpElicitationTextInputSettings settings,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    initialValue: settings.initialValue,
    label: settings.label,
    hint: settings.hint,
    isRequired: settings.isRequired,
    keyboardType: settings.keyboardType,
    maxLength: settings.maxLength,
    onChanged: settings.onChanged,
    identifier: settings.identifier,
  );
}

final class _McpElicitationTextInputSettings({
  required final _McpElicitationFieldInfo info,
  required final McpElicitationFieldValue value,
  required final ValueChanged<McpElicitationFieldValue> onValueChanged,
}) {
  final String? initialValue =
      info.schema['type'] == 'string' && info.schema['maxLength'] == 0
      ? ''
      : value?.toString();
  final Widget label = Text(info.label);
  final Widget? hint = switch (info.description) {
    final String text => Text(text),
    null => null,
  };
  final bool isRequired = info.isRequired;
  final TextInputType keyboardType = _keyboardType(
    info.schema['type'],
    info.schema['format'],
  );
  final int? maxLength = _maxLength(info.schema);
  final ValueChanged<String> onChanged = onValueChanged;
  final String identifier = 'mcp_elicitation_field_${info.name}';

  static TextInputType _keyboardType(Object? type, Object? format) =>
      switch (type) {
        'integer' => TextInputType.number,
        'number' => const TextInputType.numberWithOptions(decimal: true),
        _ => switch (format) {
          'email' => TextInputType.emailAddress,
          'uri' => TextInputType.url,
          _ => TextInputType.text,
        },
      };

  static int? _maxLength(Map<String, Object?> schema) {
    final rawLength = schema['maxLength'];
    final fieldMaxLength = schema['type'] == 'string' && rawLength is int
        ? rawLength
        : null;

    return switch (fieldMaxLength) {
      0 => 1,
      final int length when schema['pattern'] is String =>
        length < McpElicitationForm.maxPatternInputLength
            ? length
            : McpElicitationForm.maxPatternInputLength,
      null when schema['pattern'] is String =>
        McpElicitationForm.maxPatternInputLength,
      _ => fieldMaxLength,
    };
  }
}

final class _McpElicitationUrlSafety {
  static _McpElicitationUrlSummary inspect(McpElicitationRequest request) {
    final uri = request.parseExternalUri();

    return (uri: uri, host: _hostInfo(uri, _decodedUriHost(uri)));
  }

  static _McpElicitationHostInfo _hostInfo(Uri? uri, String? host) {
    final isUnicodeHost = _isUnicodeHost(host);
    final isPunycodeHost = _isPunycodeHost(host);
    final hostVerificationError = _hasHostVerificationError(
      uri,
      host,
      isUnicodeHost,
    );

    return (
      host: host,
      asciiHost: host == null || isUnicodeHost || !isPunycodeHost
          ? null
          : host.toLowerCase(),
      isInternationalized: isUnicodeHost || isPunycodeHost,
      verificationError: hostVerificationError,
    );
  }

  static String? _decodedUriHost(Uri? uri) =>
      uri == null ? null : _decodeHost(uri.host);

  static bool _isUnicodeHost(String? host) =>
      host?.runes.any((rune) => rune > 0x7F) ?? false;

  static bool _isPunycodeHost(String? host) =>
      host?.split('.').any((label) => label.toLowerCase().startsWith('xn--')) ??
      false;

  static bool _hasHostVerificationError(
    Uri? uri,
    String? host,
    bool isUnicodeHost,
  ) => uri != null && (host == null || isUnicodeHost);

  static String? _decodeHost(String host) {
    try {
      return Uri.decodeComponent(host);
    } on FormatException {
      return null;
    }
  }
}

typedef _McpElicitationHostInfo = ({
  String? host,
  String? asciiHost,
  bool isInternationalized,
  bool verificationError,
});

typedef _McpElicitationUrlSummary = ({Uri? uri, _McpElicitationHostInfo host});

void _respond(
  WidgetRef ref,
  String conversationId,
  String requestId,
  McpElicitationAction action,
) => ref
    .read(mcpElicitationProvider(conversationId).notifier)
    .respond(
      requestId: requestId,
      response: .new(action: action),
    );

String _enumOptionLabel(Map<String, Object?> schema, Object? value) {
  final choices = schema['oneOf'];
  if (choices is! List) return '$value';
  for (final choice in choices) {
    if (choice is! Map || choice['const'] != value) continue;
    final title = choice['title'];
    if (title is String) return title;
  }

  return '$value';
}
