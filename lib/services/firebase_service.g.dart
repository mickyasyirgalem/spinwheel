// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseService)
final firebaseServiceProvider = FirebaseServiceProvider._();

final class FirebaseServiceProvider
    extends
        $FunctionalProvider<FirebaseService, FirebaseService, FirebaseService>
    with $Provider<FirebaseService> {
  FirebaseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseServiceHash();

  @$internal
  @override
  $ProviderElement<FirebaseService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseService create(Ref ref) {
    return firebaseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseService>(value),
    );
  }
}

String _$firebaseServiceHash() => r'70342238cf61992552fcea00d551eec41cdd16b4';
