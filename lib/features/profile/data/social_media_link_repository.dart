import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/social_media_link.dart';

class SocialMediaLinkRepository {
  final ApiClient _apiClient;

  SocialMediaLinkRepository(this._apiClient);

  Future<List<SocialMediaLink>> fetchSocialMediaLinks() async {
    final response = await _apiClient.get(ApiEndpoints.socialMediaLinks);
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => SocialMediaLink.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      return data
          .map((item) => SocialMediaLink.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid social media links response structure');
  }
}
