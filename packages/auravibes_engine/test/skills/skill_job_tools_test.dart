import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/skills/execution/skill_job_response_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('service skill job tools', () {
    test('creates provider jobs with native request shapes', () async {
      final cases = [
        (
          skill: 'tavily',
          tool: 'research_job_create',
          input: {'query': 'latest Dart release'},
          response: '{"request_id":"tavily-1","status":"pending"}',
          url: 'https://api.tavily.com/research',
          body: contains('"input":"latest Dart release"'),
        ),
        (
          skill: 'firecrawl',
          tool: 'crawl_job_create',
          input: {'url': 'https://docs.example.com'},
          response: '{"id":"firecrawl-1"}',
          url: 'https://api.firecrawl.dev/v2/crawl',
          body: contains('"url":"https://docs.example.com"'),
        ),
        (
          skill: 'parallel',
          tool: 'tasks_job_create',
          input: {'question': 'Compare Dart and Go.'},
          response: '{"run_id":"parallel-1","status":"queued"}',
          url: 'https://api.parallel.ai/v1/tasks/runs',
          body: contains('"input":"Compare Dart and Go."'),
        ),
      ];

      for (final testCase in cases) {
        final result = await _run(
          skill: testCase.skill,
          tool: testCase.tool,
          input: testCase.input,
          response: testCase.response,
        );

        expect(result.request.method, UrlRequestMethod.post);
        expect(result.request.url, testCase.url);
        expect(result.request.body, testCase.body);
        expect(result.value['provider'], testCase.skill);
        expect(result.value['jobId'], isNotEmpty);
        expect(result.value['status'], 'pending');
        expect(result.value['pollAfterSeconds'], 5);
      }
    });

    test('normalizes pending and completed polls', () async {
      final pending = await _run(
        skill: 'tavily',
        tool: 'research_job_status',
        input: {'jobId': 'tavily-1'},
        response: '{"request_id":"tavily-1","status":"in_progress"}',
        statusCode: 202,
      );
      expect(pending.request.method, UrlRequestMethod.get);
      expect(pending.request.url, 'https://api.tavily.com/research/tavily-1');
      expect(pending.value, {
        'jobId': 'tavily-1',
        'status': 'running',
        'outputReady': false,
        'raw': {'request_id': 'tavily-1', 'status': 'in_progress'},
      });

      final completed = await _run(
        skill: 'parallel',
        tool: 'tasks_job_status',
        input: {'jobId': 'parallel-1'},
        response: '''
{"run_id":"parallel-1","status":"completed","result":{"answer":"done"}}
''',
      );
      expect(completed.value['jobId'], 'parallel-1');
      expect(completed.value['status'], 'completed');
      expect(completed.value['outputReady'], isTrue);
    });

    test('returns final output from a result endpoint', () async {
      final result = await _run(
        skill: 'parallel',
        tool: 'tasks_job_output',
        input: {'jobId': 'parallel-1'},
        response: '{"answer":"done"}',
      );

      expect(result.request.url, endsWith('/v1/tasks/runs/parallel-1/result'));
      expect(result.value['status'], 'completed');
      expect(result.value['outputReady'], isTrue);
      expect(result.value['output'], {'answer': 'done'});
    });

    test('cancels a supported Firecrawl job', () async {
      final result = await _run(
        skill: 'firecrawl',
        tool: 'crawl_job_cancel',
        input: {'jobId': 'firecrawl-1'},
        response: '{"success":true,"id":"firecrawl-1"}',
      );

      expect(result.request.method, UrlRequestMethod.delete);
      expect(result.request.url, endsWith('/v2/crawl/firecrawl-1'));
      expect(result.value['cancelled'], isTrue);
      expect(result.value['status'], 'cancelled');
    });

    test('reports unsupported and failed cancellation explicitly', () {
      const decoder = SkillJobResponseDecoder();

      expect(
        jsonDecode(
          decoder(
            provider: 'tavily',
            operation: AppSkillJobOperation.cancel,
            statusCode: 200,
            body: '{"request_id":"tavily-1"}',
            requestedJobId: 'tavily-1',
          ),
        ),
        {
          'jobId': 'tavily-1',
          'cancelled': false,
          'status': 'unsupported',
          'message': 'Remote job cancellation is not supported by tavily.',
          'raw': {'request_id': 'tavily-1'},
        },
      );

      expect(
        jsonDecode(
          decoder(
            provider: 'firecrawl',
            operation: AppSkillJobOperation.cancel,
            statusCode: 500,
            body: '{"error":{"message":"provider unavailable"}}',
            requestedJobId: 'firecrawl-1',
          ),
        ),
        {
          'jobId': 'firecrawl-1',
          'cancelled': false,
          'status': 'failed',
          'message': 'provider unavailable',
          'raw': {
            'error': {'message': 'provider unavailable'},
          },
        },
      );
    });
  });
}

Future<({UrlRequest request, Map<String, dynamic> value})> _run({
  required String skill,
  required String tool,
  required Map<String, dynamic> input,
  required String response,
  int statusCode = 200,
}) async {
  late UrlRequest request;
  final executor = AppSkillExecutor(
    SkillTemplateExecutor(const ResolveSkillUrlTemplate(), (resolvedRequest) {
      request = resolvedRequest;

      return CancelableOperation.fromFuture(
        Future.value(
          UrlResponse(
            statusCode: statusCode,
            body: response,
            headers: const {},
            elapsed: .zero,
          ),
        ),
      );
    }),
  );
  final result = await executor
      .run(
        skill: serviceSkillDefinitions.singleWhere(
          (candidate) => candidate.slug == skill,
        ),
        toolSlug: tool,
        input: input,
        credentials: const {'apiKey': 'test-key'},
      )
      .value;

  if (result is! String) {
    throw StateError('Job response must be JSON text.');
  }

  return (request: request, value: jsonDecode(result) as Map<String, dynamic>);
}
