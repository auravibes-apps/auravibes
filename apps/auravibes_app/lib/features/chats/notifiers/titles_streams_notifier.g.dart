// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'titles_streams_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TitlesStreamsNotifier)
final titlesStreamsProvider = TitlesStreamsNotifierProvider._();

final class TitlesStreamsNotifierProvider
    extends $NotifierProvider<TitlesStreamsNotifier, Map<String, String>> {
  TitlesStreamsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'titlesStreamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$titlesStreamsNotifierHash();

  @$internal
  @override
  TitlesStreamsNotifier create() => TitlesStreamsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$titlesStreamsNotifierHash() =>
    r'ff80c1be226aa5641e80c14cc5864b9bf98ce56f';

abstract class _$TitlesStreamsNotifier extends $Notifier<Map<String, String>> {
  Map<String, String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
