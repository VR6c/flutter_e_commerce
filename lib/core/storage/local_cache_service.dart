import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/models/banner.dart';
import '../../features/categories/models/category.dart';
import '../../features/products/models/product.dart';

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

class LocalCacheService {
  static const String _kProductsKey = 'cached_products_v1';
  static const String _kCategoriesKey = 'cached_categories_v2';
  static const String _kBannersKey = 'cached_banners_v1';
  static const String _kSuggestionsKey = 'cached_suggestions_v1';
  static const String _kCategoryProductsPrefix = 'cached_cat_prods_v1_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Products ─────────────────────────────────────────────────────────────

  Future<List<Product>?> getCachedProducts() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kProductsKey);
      if (raw == null || raw.isEmpty) return null;

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final products = decoded
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (products.isEmpty) return null;
      return products;
    } catch (e) {
      debugPrint('Error reading cached products: $e');
      return null;
    }
  }

  Future<void> saveCachedProducts(List<Product> products) async {
    if (products.isEmpty) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
      await prefs.setString(_kProductsKey, encoded);
    } catch (e) {
      debugPrint('Error saving cached products: $e');
    }
  }

  // ── Categories ───────────────────────────────────────────────────────────

  Future<List<Category>?> getCachedCategories() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kCategoriesKey);
      if (raw == null || raw.isEmpty) return null;

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final categories = decoded
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (categories.isEmpty) return null;
      return categories;
    } catch (e) {
      debugPrint('Error reading cached categories: $e');
      return null;
    }
  }

  Future<void> saveCachedCategories(List<Category> categories) async {
    if (categories.isEmpty) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
      await prefs.setString(_kCategoriesKey, encoded);
    } catch (e) {
      debugPrint('Error saving cached categories: $e');
    }
  }

  // ── Banners ──────────────────────────────────────────────────────────────

  Future<List<BannerModel>?> getCachedBanners() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kBannersKey);
      if (raw == null || raw.isEmpty) return null;

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final banners = decoded
          .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (banners.isEmpty) return null;
      return banners;
    } catch (e) {
      debugPrint('Error reading cached banners: $e');
      return null;
    }
  }

  Future<void> saveCachedBanners(List<BannerModel> banners) async {
    if (banners.isEmpty) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(banners.map((b) => b.toJson()).toList());
      await prefs.setString(_kBannersKey, encoded);
    } catch (e) {
      debugPrint('Error saving cached banners: $e');
    }
  }

  // ── Suggestions ──────────────────────────────────────────────────────────
  Future<List<Product>?> getCachedSuggestions() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kSuggestionsKey);
      if (raw == null || raw.isEmpty) return null;

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final products = decoded
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (products.isEmpty) return null;
      return products;
    } catch (e) {
      debugPrint('Error reading cached suggestions: $e');
      return null;
    }
  }

  Future<void> saveCachedSuggestions(List<Product> products) async {
    if (products.isEmpty) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
      await prefs.setString(_kSuggestionsKey, encoded);
    } catch (e) {
      debugPrint('Error saving cached suggestions: $e');
    }
  }

  // ── Category-Specific Products ──────────────────────────────────────────

  Future<List<Product>?> getCachedCategoryProducts(int categoryId) async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString('$_kCategoryProductsPrefix$categoryId');
      if (raw == null || raw.isEmpty) return null;

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final products = decoded
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (products.isEmpty) return null;
      return products;
    } catch (e) {
      debugPrint('Error reading cached category products for $categoryId: $e');
      return null;
    }
  }

  Future<void> saveCachedCategoryProducts(int categoryId, List<Product> products) async {
    if (products.isEmpty) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
      await prefs.setString('$_kCategoryProductsPrefix$categoryId', encoded);
    } catch (e) {
      debugPrint('Error saving cached category products for $categoryId: $e');
    }
  }

  // ── Clear All Cache ──────────────────────────────────────────────────────

  Future<void> clearAll() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_kProductsKey);
      await prefs.remove(_kCategoriesKey);
      await prefs.remove(_kBannersKey);
      await prefs.remove(_kSuggestionsKey);
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_kCategoryProductsPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
