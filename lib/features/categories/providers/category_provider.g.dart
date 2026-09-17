part of 'category_provider.dart';

String _$categoriesHash() => r'b5ab535144e7cbf151abb7fd9f71f2941704252f';

/// See also [Categories].
@ProviderFor(Categories)
final categoriesProvider =
    AsyncNotifierProvider<Categories, List<Category>>.internal(
      Categories.new,
      name: r'categoriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Categories = AsyncNotifier<List<Category>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
