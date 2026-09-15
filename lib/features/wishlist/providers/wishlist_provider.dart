import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/providers.dart';
import '../../products/models/product.dart';
import '../../auth/providers/auth_provider.dart';

part 'wishlist_provider.g.dart';

String _wishlistKey(int userId) => 'wishlist_items_$userId';

@riverpod
class Wishlist extends _$Wishlist {
  @override
  List<Product> build() {
    // Watch auth state — rebuild (and clear) whenever the user changes
    final authAsync = ref.watch(authStateProvider);
    final customer = authAsync.valueOrNull;

    if (customer == null) {
      // Not signed in — always return empty, do not load persisted data
      return [];
    }

    // 1. Immediately load persisted local items for instantaneous UI
    _loadPersistedWishlist(customer.id).then((_) {
      // 2. Then sync with the remote Laravel backend API
      _syncWithApi(customer.id);
    });

    return [];
  }

  // ── Remote API Sync ────────────────────────────────────────────────────────

  Future<void> _syncWithApi(int userId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get<Map<String, dynamic>>(ApiEndpoints.wishlist);
      final data = response.data;

      if (data != null && data['data'] is List) {
        final rawList = data['data'] as List<dynamic>;
        final serverProducts = rawList
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();

        state = serverProducts;
        await _persistWishlist(serverProducts);
      }
    } catch (_) {
      // Offline or network error: retain local cached state silently
    }
  }

  Future<void> _apiToggle(int productId, {String? action}) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final body = <String, dynamic>{'product_id': productId};
      if (action != null) body['action'] = action;
      await apiClient.post(ApiEndpoints.wishlistToggle, data: body);
    } catch (_) {
      // Silently catch to ensure optimistic UI does not break
    }
  }

  Future<void> _apiRemove(int productId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete(ApiEndpoints.wishlistDelete(productId));
    } catch (_) {
      // Silently catch
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadPersistedWishlist(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_wishlistKey(userId));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final items = decoded
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        state = items;
      }
    } catch (_) {
      // Silently ignore persistence errors — fall back to empty wishlist
    }
  }

  Future<void> _persistWishlist(List<Product> items) async {
    final customer = ref.read(authStateProvider).valueOrNull;
    if (customer == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_wishlistKey(customer.id), encoded);
    } catch (_) {
      // Silently ignore
    }
  }

  // ── Wishlist operations ────────────────────────────────────────────────────

  /// Returns false if the user is not signed in (caller should show login prompt).
  bool toggleItem(Product product) {
    if (ref.read(authStateProvider).valueOrNull == null) return false;

    final exists = state.any((p) => p.id == product.id);
    final next = exists
        ? state.where((p) => p.id != product.id).toList()
        : [...state, product];
    state = next;
    _persistWishlist(next);

    // Sync with backend API
    _apiToggle(product.id);

    return true;
  }

  void removeItem(int productId) {
    if (ref.read(authStateProvider).valueOrNull == null) return;
    final next = state.where((p) => p.id != productId).toList();
    state = next;
    _persistWishlist(next);

    // Sync with backend API
    _apiRemove(productId);
  }

  void clear() {
    if (ref.read(authStateProvider).valueOrNull == null) return;
    final currentIds = state.map((p) => p.id).toList();
    state = [];
    _persistWishlist([]);

    // Sync with backend API in parallel
    if (currentIds.isNotEmpty) {
      Future.wait(currentIds.map((id) => _apiRemove(id)));
    }
  }

  bool isInWishlist(int productId) {
    return state.any((p) => p.id == productId);
  }

  /// Manually trigger a refresh from the backend API
  Future<void> refresh() async {
    final customer = ref.read(authStateProvider).valueOrNull;
    if (customer != null) {
      await _syncWithApi(customer.id);
    }
  }
}

/// Convenience provider — true if the given product is wishlisted.
final isInWishlistProvider = Provider.family<bool, int>((ref, productId) {
  final wishlist = ref.watch(wishlistProvider);
  return wishlist.any((p) => p.id == productId);
});

/// Count of wishlisted items.
final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider).length;
});
