class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://e-commers-laravel.vercel.app/api';

  // Auth endpoints
  static const String login = '/customer/login';
  static const String register = '/customer/register';
  static const String profile = '/customer/profile';
  static const String logout = '/customer/logout';
  static const String refreshToken = '/customer/refresh';

  // Feature endpoints
  static const String products = '/products';
  static const String productSuggestions = '/products/suggestions';
  static String productRelated(String slug) => '/products/$slug/suggestions';
  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String orders = '/orders';
  static const String banners = '/banners';
  static const String coupons = '/coupons';
  static const String socialMediaLinks = '/social-media-links';
}
