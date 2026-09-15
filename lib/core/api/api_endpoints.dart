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
  static String productDetail(String slug) => '/products/$slug';
  static String productReviews(String slug) => '/products/$slug/reviews';

  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String banners = '/banners';
  static const String coupons = '/coupons';
  static const String socialMediaLinks = '/social-media-links';

  // Orders
  static const String orders = '/orders';
  static String orderDetail(dynamic id) => '/orders/$id';
  static String orderReceipt(dynamic id) => '/orders/$id/receipt';

  // Wishlist
  static const String wishlist = '/wishlist';
  static const String wishlistToggle = '/wishlist/toggle';
  static const String wishlistIds = '/wishlist/ids';
  static String wishlistDelete(dynamic productId) => '/wishlist/$productId';

  // Deprecated aliases for backwards compatibility
  static const String wishlists = wishlist;
}
