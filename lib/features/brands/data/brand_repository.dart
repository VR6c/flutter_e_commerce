import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/image_url_formatter.dart';
import '../models/brand.dart';

class BrandRepository {
  final ApiClient _apiClient;

  BrandRepository(this._apiClient);

  Future<List<Brand>> fetchBrands() async {
    final response = await _apiClient.get(ApiEndpoints.brands);
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      final baseUrl = _apiClient.dio.options.baseUrl;
      return (data['data'] as List).map((item) {
        final json = Map<String, dynamic>.from(item as Map);
        if (json['logo_url'] != null) {
          json['logo_url'] = formatImageUrl(
            json['logo_url'].toString(),
            baseUrl,
            title: json['name']?.toString(),
            slug: json['slug']?.toString(),
          );
        }
        return Brand.fromJson(json);
      }).toList();
    }
    throw Exception('Invalid brands response structure');
  }
}
