import 'dart:convert';

import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';

class const SkillJobResponseDecoder() {
  String call({
    required String provider,
    required AppSkillJobOperation operation,
    required int statusCode,
    required String body,
    String? requestedJobId,
  }) {
    final payload = _decode(body);
    final jobId =
        requestedJobId ??
        _string(payload, const [
          'jobId',
          'job_id',
          'request_id',
          'run_id',
          'id',
        ]);
    final status = _jobStatus(
      payload: payload,
      statusCode: statusCode,
      operation: operation,
      jobId: jobId,
    );
    final raw = payload ?? body;

    final response = switch (operation) {
      AppSkillJobOperation.create => {
        'provider': provider,
        'jobId': jobId,
        'status': status,
        if (status == 'pending' || status == 'running') 'pollAfterSeconds': 5,
        'raw': raw,
      },
      AppSkillJobOperation.status => _statusResponse(
        jobId: jobId,
        status: status,
        payload: payload,
        raw: raw,
      ),
      AppSkillJobOperation.cancel => _cancelResponse(
        provider: provider,
        jobId: jobId,
        status: status,
        payload: payload,
        raw: raw,
        statusCode: statusCode,
      ),
      AppSkillJobOperation.output => {
        'jobId': jobId,
        'status': status,
        'outputReady': status == 'completed',
        'output': _output(payload, fallbackToPayload: status == 'completed'),
        'raw': raw,
      },
    };

    return jsonEncode(response);
  }

  Map<String, Object?> _statusResponse({
    required String? jobId,
    required String status,
    required Map<String, Object?>? payload,
    required Object raw,
  }) {
    final progress = _progress(payload);
    final message = _message(payload);
    final response = <String, Object?>{
      'jobId': jobId,
      'status': status,
      'outputReady': status == 'completed',
      'raw': raw,
    };
    if (progress != null) response['progress'] = progress;
    if (message != null) response['message'] = message;

    return response;
  }

  Map<String, Object?> _cancelResponse({
    required String provider,
    required String? jobId,
    required String status,
    required Map<String, Object?>? payload,
    required Object raw,
    required int statusCode,
  }) {
    if (provider != 'firecrawl') {
      return {
        'jobId': jobId,
        'cancelled': false,
        'status': 'unsupported',
        'message': 'Remote job cancellation is not supported by $provider.',
        'raw': raw,
      };
    }

    final cancelled =
        statusCode >= 200 &&
        statusCode < 300 &&
        payload?['success'] != false &&
        status != 'failed';
    final message = _message(payload);
    final response = <String, Object?>{
      'jobId': jobId,
      'cancelled': cancelled,
      'status': cancelled ? 'cancelled' : status,
      'raw': raw,
    };
    if (!cancelled && message != null) response['message'] = message;

    return response;
  }

  Object? _output(
    Map<String, Object?>? payload, {
    required bool fallbackToPayload,
  }) {
    if (payload == null) return null;
    for (final key in const ['output', 'content', 'result', 'data']) {
      if (payload.containsKey(key)) return payload[key];
    }

    return fallbackToPayload ? payload : null;
  }

  double? _progress(Map<String, Object?>? payload) {
    final progress = payload?['progress'];
    if (progress is num) return progress.toDouble();

    final completed = payload?['completed'];
    final total = payload?['total'];
    if (completed is num && total is num && total > 0) {
      return completed / total;
    }

    return null;
  }

  String? _message(Map<String, Object?>? payload) =>
      _text(payload?['message']) ??
      _errorMessage(payload?['error']) ??
      _errorListMessage(payload?['errors']);

  String _jobStatus({
    required Map<String, Object?>? payload,
    required int statusCode,
    required AppSkillJobOperation operation,
    required String? jobId,
  }) {
    final status = _status(payload, statusCode);
    if (status != 'unknown' || statusCode >= 400) return status;
    if (statusCode == 202) return 'pending';
    if (operation == AppSkillJobOperation.create && jobId != null) {
      return 'pending';
    }
    if (operation == AppSkillJobOperation.output && statusCode < 300) {
      return 'completed';
    }

    return status;
  }

  String _status(Map<String, Object?>? payload, int statusCode) {
    if (statusCode >= 400) return 'failed';

    final value = _string(payload, const ['status', 'state']);
    if (value == null) return 'unknown';

    return switch (value.toLowerCase().replaceAll('-', '_')) {
      'pending' || 'queued' || 'created' => 'pending',
      'in_progress' || 'running' || 'processing' || 'scraping' => 'running',
      'completed' ||
      'complete' ||
      'succeeded' ||
      'success' ||
      'done' => 'completed',
      'failed' || 'failure' || 'error' => 'failed',
      'cancelled' || 'canceled' => 'cancelled',
      _ => 'unknown',
    };
  }

  String? _string(Map<String, Object?>? payload, List<String> keys) {
    if (payload == null) return null;
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) return value;
    }

    return null;
  }

  Map<String, Object?>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }
}

String? _text(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

String? _errorMessage(Object? error) => switch (error) {
  final String value => _text(value),
  final Map<Object?, Object?> value => _text(value['message']),
  _ => null,
};

String? _errorListMessage(Object? errors) {
  if (errors is! List) return null;
  for (final error in errors) {
    final message = _errorMessage(error);
    if (message != null) return message;
  }

  return null;
}
