import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/providers.dart';
import '../data/social_media_link_repository.dart';
import '../models/social_media_link.dart';

part 'social_media_link_provider.g.dart';

final socialMediaLinkRepositoryProvider = Provider<SocialMediaLinkRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialMediaLinkRepository(apiClient);
});

@riverpod
class SocialMediaLinks extends _$SocialMediaLinks {
  @override
  FutureOr<List<SocialMediaLink>> build() async {
    return ref.watch(socialMediaLinkRepositoryProvider).fetchSocialMediaLinks();
  }
}
