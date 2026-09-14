import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/providers.dart';
import '../data/brand_repository.dart';
import '../models/brand.dart';

part 'brand_provider.g.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BrandRepository(apiClient);
});

@riverpod
class Brands extends _$Brands {
  @override
  FutureOr<List<Brand>> build() async {
    return ref.watch(brandRepositoryProvider).fetchBrands();
  }
}
