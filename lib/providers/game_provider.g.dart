// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameCtrl)
final gameCtrlProvider = GameCtrlProvider._();

final class GameCtrlProvider extends $NotifierProvider<GameCtrl, GameState> {
  GameCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameCtrlHash();

  @$internal
  @override
  GameCtrl create() => GameCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameState>(value),
    );
  }
}

String _$gameCtrlHash() => r'd571b7dcbc1a7bb182c34dabb0dd90643f810d01';

abstract class _$GameCtrl extends $Notifier<GameState> {
  GameState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GameState, GameState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GameState, GameState>,
              GameState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
