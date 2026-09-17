part of 'banner_provider.dart';

String _$bannersHash() => r'f1c50486adb437ca990848f8a618d3b43f840309';

/// See also [Banners].
@ProviderFor(Banners)
final bannersProvider =
    AsyncNotifierProvider<Banners, List<BannerModel>>.internal(
      Banners.new,
      name: r'bannersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bannersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Banners = AsyncNotifier<List<BannerModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
