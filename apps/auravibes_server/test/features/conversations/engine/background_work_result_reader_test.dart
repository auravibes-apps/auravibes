import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/background_work_result_reader.dart';
import 'package:test/test.dart';

void main() {
  test('reader schema is strict and requires bounded page arguments', () {
    final schema = Map<String, dynamic>.from(
      backgroundWorkResultReaderToolSpec().inputJsonSchema,
    );

    expect(strictToolSchemaIssue(schema), isNull);
    expect(schema['required'], ['work_id', 'offset', 'max_bytes']);
    expect(schema['additionalProperties'], isFalse);
  });

  test('reader returns bounded UTF-8 chunks and preserves character edges', () {
    final first = backgroundWorkResultPage(
      workId: 'work-1',
      status: 'completed',
      resultContent: 'a🙂bc',
      resultByteLength: 7,
      offset: 0,
      maxBytes: 3,
    );
    expect(first['content'], 'a');
    expect(first['next_offset'], 1);
    expect(first['complete'], isFalse);
    expect(first['untrusted'], isTrue);

    final second = backgroundWorkResultPage(
      workId: 'work-1',
      status: 'completed',
      resultContent: 'a🙂bc',
      resultByteLength: 7,
      offset: 1,
      maxBytes: 4,
    );
    expect(second['content'], '🙂');
    expect(second['next_offset'], 5);
  });

  test('reader discloses stored truncation and rejects negative offsets', () {
    final page = backgroundWorkResultPage(
      workId: 'work-2',
      status: 'completed',
      resultContent: 'partial',
      resultByteLength: 100,
      offset: 0,
      maxBytes: maxBackgroundWorkResultPageBytes + 100,
    );

    expect(page['stored_byte_length'], 7);
    expect(page['original_byte_length'], 100);
    expect(page['truncated'], isTrue);
    expect(page['warning'], contains('untrusted'));
    expect(
      () => backgroundWorkResultPage(
        workId: 'work-2',
        status: 'completed',
        resultContent: 'partial',
        resultByteLength: 7,
        offset: -1,
        maxBytes: 1,
      ),
      throwsFormatException,
    );
    expect(
      () => backgroundWorkResultPage(
        workId: 'work-2',
        status: 'completed',
        resultContent: '🙂',
        resultByteLength: 4,
        offset: 0,
        maxBytes: 1,
      ),
      throwsFormatException,
    );
  });
}
