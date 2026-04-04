import 'dart:async';

import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoalescingSaveExtension', () {
    test('emits saved state after each store completes', () async {
      final savedStates = <int>[];
      final controller = StreamController<int>();

      final output = controller.stream.coalescingSave(
        store: (state) async {
          savedStates.add(state);
        },
      );

      controller
        ..add(1)
        ..add(2)
        ..add(3)
        ..close();

      final results = await output.toList();
      expect(results, [1, 2, 3]);
      expect(savedStates, [1, 2, 3]);
    });

    test('coalesces rapid emissions - only saves latest', () async {
      final savedStates = <int>[];
      final controller = StreamController<int>();

      final output = controller.stream.coalescingSave(
        store: (state) async {
          savedStates.add(state);
        },
      );

      // Rapid emissions before any await completes
      controller
        ..add(1)
        ..add(2)
        ..add(3);

      // Wait a bit then add more
      await Future<void>.delayed(Duration.zero);
      controller
        ..add(4)
        ..add(5)
        ..close();

      final results = await output.toList();
      // Due to coalescing during async await,
      // intermediate states may be skipped
      // but the final state (5) should be present
      expect(results.last, 5);
      expect(savedStates.last, 5);
    });

    test('.last returns final saved state after stream closes', () async {
      final savedStates = <String>[];
      final controller = StreamController<String>();

      final output = controller.stream.coalescingSave(
        store: (state) async {
          savedStates.add(state);
        },
      );

      controller
        ..add('initial')
        ..add('middle')
        ..add('final')
        ..close();

      final lastState = await output.last;
      expect(lastState, 'final');
      expect(savedStates.last, 'final');
    });

    test('store errors are swallowed and loop continues', () async {
      final savedStates = <int>[];
      final controller = StreamController<int>();
      var errorCount = 0;

      final output = controller.stream.coalescingSave(
        store: (state) async {
          savedStates.add(state);
          if (state == 2) {
            errorCount++;
            throw Exception('test error');
          }
        },
      );

      controller
        ..add(1)
        ..add(2)
        ..add(3)
        ..close();

      final results = await output.toList();
      // State 2 throws error, so it's not emitted - but 1 and 3 are
      expect(results, [1, 3]);
      // All states are attempted to be saved
      expect(savedStates, [1, 2, 3]);
      expect(errorCount, 1);
    });

    test('handles empty stream gracefully', () async {
      final controller = StreamController<int>();
      final savedStates = <int>[];

      final output = controller.stream.coalescingSave(
        store: (state) async {
          savedStates.add(state);
        },
      );

      controller.close();

      final results = await output.toList();
      expect(results, isEmpty);
      expect(savedStates, isEmpty);
    });

    test('handles single emission', () async {
      final savedStates = <int>[];
      final controller = StreamController<int>();

      final output = controller.stream.coalescingSave(
        store: (state) async {
          savedStates.add(state);
        },
      );

      controller
        ..add(42)
        ..close();

      final results = await output.toList();
      expect(results, [42]);
      expect(savedStates, [42]);
    });

    test('waits for the final async save before closing', () async {
      final savedStates = <int>[];
      final controller = StreamController<int>();

      final output = controller.stream.coalescingSave(
        store: (state) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          savedStates.add(state);
        },
      );

      controller
        ..add(42)
        ..close();

      final results = await output.toList();
      expect(results, [42]);
      expect(savedStates, [42]);
    });

    test('state is emitted only after store completes', () async {
      final storeTimestamps = <int>[];
      final emitTimestamps = <int, int>{};
      var emitIndex = 0;
      final controller = StreamController<int>();

      controller.stream
          .coalescingSave(
            store: (state) async {
              storeTimestamps.add(state);
            },
          )
          .listen((state) {
            emitTimestamps[state] = emitIndex++;
          });

      controller
        ..add(1)
        ..add(2)
        ..close();

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // State 1 should be emitted before state 2
      expect(emitTimestamps[1], lessThan(emitTimestamps[2]!));
      // Store should happen in order
      expect(storeTimestamps, [1, 2]);
    });

    test('freshest state is used when complete is called', () async {
      final savedStates = <String>[];
      final controller = StreamController<String>();

      final output = controller.stream.coalescingSave(
        store: (state) async {
          savedStates.add(state);
        },
      );

      controller
        ..add('first')
        ..add('second')
        ..close();

      final lastState = await output.last;
      expect(lastState, 'second');
      expect(savedStates.last, 'second');
    });
  });
}
