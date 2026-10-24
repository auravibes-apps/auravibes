import 'dart:async';

import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('chat asset locator waits for current authorization', (
    tester,
  ) async {
    final pending = Completer<WorkspaceAssetPreview>();
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: ChatAttachmentImage(
            localPath: 'workspace-asset://asset/asset-test/one/asset',
          ),
        ),
        overrides: [
          appStorageNamespaceProvider.overrideWithValue('asset-test'),
          workspaceAssetPreviewProvider(
            'one',
            'asset',
          ).overrideWith((_) => pending.future),
        ],
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    pending.completeError(const WorkspaceAssetException(.denied));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
