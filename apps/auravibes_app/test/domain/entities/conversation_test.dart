import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025);

  group('ConversationEntity', () {
    final entity = ConversationEntity(
      id: 'conv_1',
      title: 'My Chat',
      workspaceId: 'ws_1',
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );

    test('hasValidTitle true when title is not empty', () {
      expect(entity.hasValidTitle, isTrue);
    });

    test('hasValidTitle false when title is empty', () {
      final empty = ConversationEntity(
        id: 'conv_2',
        title: '',
        workspaceId: 'ws_1',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(empty.hasValidTitle, isFalse);
    });

    test('isValid true when title and workspaceId are valid', () {
      expect(entity.isValid, isTrue);
    });

    test('isValid false when workspaceId is empty', () {
      final invalid = ConversationEntity(
        id: 'conv_3',
        title: 'Chat',
        workspaceId: '',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(invalid.isValid, isFalse);
    });

    test('isValid false when title is empty', () {
      final invalid = ConversationEntity(
        id: 'conv_4',
        title: '',
        workspaceId: 'ws_1',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(invalid.isValid, isFalse);
    });

    test('isPinned field', () {
      final pinned = ConversationEntity(
        id: 'conv_5',
        title: 'Pinned',
        workspaceId: 'ws_1',
        isPinned: true,
        createdAt: now,
        updatedAt: now,
      );
      expect(pinned.isPinned, isTrue);
    });

    test('modelId is optional', () {
      expect(entity.modelId, isNull);
      final withModel = ConversationEntity(
        id: 'conv_6',
        title: 'With Model',
        workspaceId: 'ws_1',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
        modelId: 'model_1',
      );
      expect(withModel.modelId, 'model_1');
    });
  });

  group('ConversationToCreate', () {
    test('hasValidTitle and isValid', () {
      const create = ConversationToCreate(
        title: 'New Chat',
        workspaceId: 'ws_1',
      );
      expect(create.hasValidTitle, isTrue);
      expect(create.isValid, isTrue);
    });

    test('isValid false when workspaceId is empty', () {
      const create = ConversationToCreate(
        title: 'New Chat',
        workspaceId: '',
      );
      expect(create.isValid, isFalse);
    });

    test('hasValidTitle false when title is empty', () {
      const create = ConversationToCreate(
        title: '',
        workspaceId: 'ws_1',
      );
      expect(create.hasValidTitle, isFalse);
      expect(create.isValid, isFalse);
    });

    test('optional modelId and isPinned', () {
      const create = ConversationToCreate(
        title: 'Chat',
        workspaceId: 'ws_1',
        modelId: 'model_1',
        isPinned: true,
      );
      expect(create.modelId, 'model_1');
      expect(create.isPinned, isTrue);
    });

    test('isValid false when modelId is set to empty', () {
      const create = ConversationToCreate(
        title: 'Chat',
        workspaceId: 'ws_1',
        modelId: '',
      );
      expect(create.isValid, isFalse);
    });
  });

  group('ConversationPatch', () {
    test('isValid true when title is set', () {
      const patch = ConversationPatch(title: 'Updated');
      expect(patch.isValid, isTrue);
    });

    test('isValid true when modelId is set', () {
      const patch = ConversationPatch(modelId: 'model_2');
      expect(patch.isValid, isTrue);
    });

    test('isValid true when isPinned is set', () {
      const patch = ConversationPatch(isPinned: true);
      expect(patch.isValid, isTrue);
    });

    test('isValid false when all fields are null', () {
      const patch = ConversationPatch();
      expect(patch.isValid, isFalse);
    });

    test('isValid false when title is set to empty', () {
      const patch = ConversationPatch(title: '');
      expect(patch.isValid, isFalse);
    });

    test('isValid false when modelId is set to empty', () {
      const patch = ConversationPatch(modelId: '');
      expect(patch.isValid, isFalse);
    });

    test('isValid true when isPinned and other field set', () {
      const patch = ConversationPatch(title: 'X', isPinned: false);
      expect(patch.isValid, isTrue);
    });
  });
}
