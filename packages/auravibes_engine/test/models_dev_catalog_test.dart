import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('parses models.dev catalog values and rejects malformed entries', () {
    final catalog = ModelsDevCatalogValue.parse({
      'openai': {
        'id': 'openai',
        'models': {
          'gpt': {'id': 'gpt'},
        },
      },
    });
    expect(catalog.models.single.capabilities.id, 'gpt');
    expect(
      () => ModelsDevCatalogValue.parse({
        'openai': <String, Object?>{
          'id': 'other',
          'models': <String, Object?>{},
        },
      }),
      throwsFormatException,
    );
  });

  test('rejects catalogs before allocating beyond supplied limits', () {
    final provider = <String, Object?>{
      'id': 'openai',
      'models': <String, Object?>{
        'gpt-1': <String, Object?>{'id': 'gpt-1'},
        'gpt-2': <String, Object?>{'id': 'gpt-2'},
      },
    };

    expect(
      () => ModelsDevCatalogValue.parse(<String, Object?>{
        'openai': provider,
      }, maxModels: 1),
      throwsFormatException,
    );
  });

  test('rejects nested maps with non-string keys as malformed input', () {
    expect(
      () => ModelsDevCatalogValue.parse(<String, Object?>{
        'openai': <Object?, Object?>{
          'id': 'openai',
          'models': <String, Object?>{},
          1: 'invalid',
        },
      }),
      throwsFormatException,
    );
  });
}
