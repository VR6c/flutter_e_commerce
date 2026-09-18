import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/image_url_formatter.dart';
import '../models/banner.dart';

class BannerRepository {
  final ApiClient _apiClient;

  BannerRepository(this._apiClient);

  Future<List<BannerModel>> fetchBanners() async {
    final response = await _apiClient.get(ApiEndpoints.banners);
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      final baseUrl = _apiClient.dio.options.baseUrl;
      return (data['data'] as List)
          .map((item) {
            final json = Map<String, dynamic>.from(item as Map);
            json['image_url'] = formatImageUrl(
              json['image_url']?.toString(),
              baseUrl,
              title: json['title']?.toString(),
              slug: json['type']?.toString(),
              isBanner: true,
            );
            return BannerModel.fromJson(json);
          })
          .toList();
    }
    throw Exception('Invalid banners response structure');
  }
}
