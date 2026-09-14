import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/categories/screens/category_list_screen.dart';
import '../../features/categories/screens/category_products_screen.dart';
import '../../features/brands/screens/brand_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/scaffold_with_bottom_nav.dart';
import '../../features/products/models/product.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/cart/screens/checkout_screen.dart';
import '../../features/orders/screens/order_history_screen.dart';
import '../../features/cart/screens/order_success_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/profile/screens/avatar_customizer_screen.dart';
import '../../features/ai_assistant/screens/ai_assistant_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      // If logged in and lands on login or register → go home
      if (isAuthenticated &&
          (loc == AppRoutes.login || loc == AppRoutes.register)) {
        return AppRoutes.home;
      }

      // All other routes are freely accessible (guest-friendly)
      return null;
    },
    routes: [
      // ── Standalone Screens ─────────────────────────────────────────
      GoRoute(
        name: AppRoutes.splashName,
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: AppRoutes.loginName,
        path: AppRoutes.login,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final returnTo = extra?['returnTo'] as String? ?? AppRoutes.home;
          return LoginScreen(returnTo: returnTo);
        },
      ),
      GoRoute(
        name: AppRoutes.registerName,
        path: AppRoutes.register,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final returnTo = extra?['returnTo'] as String? ?? AppRoutes.home;
          return RegisterScreen(returnTo: returnTo);
        },
      ),
      GoRoute(
        name: AppRoutes.productDetailName,
        path: AppRoutes.productDetail,
        pageBuilder: (context, state) {
          Product product;
          String? heroTag;

          if (state.extra is Product) {
            product = state.extra as Product;
          } else if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            product = extra['product'] as Product;
            heroTag = extra['heroTag'] as String?;
          } else {
            throw ArgumentError(
              'Invalid extra for productDetail: ${state.extra}',
            );
          }

          heroTag ??= state.uri.queryParameters['heroTag'];

          return CustomTransitionPage(
            key: state.pageKey,
            child: ProductDetailScreen(
              product: product,
              heroTag: heroTag,
            ),
            transitionDuration: const Duration(milliseconds: 320),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curvedAnimation,
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        name: AppRoutes.categoryProductsName,
        path: AppRoutes.categoryProducts,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CategoryProductsScreen(
            categoryName: extra['categoryName'] as String,
            categorySlugs: List<String>.from(extra['categorySlugs'] as List),
          );
        },
      ),
      GoRoute(
        name: AppRoutes.brandsName,
        path: AppRoutes.brands,
        builder: (context, state) => const BrandListScreen(),
      ),
      GoRoute(
        name: AppRoutes.cartName,
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        name: AppRoutes.checkoutName,
        path: AppRoutes.checkout,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isGuest = extra?['isGuest'] as bool? ?? false;
          return CheckoutScreen(isGuest: isGuest);
        },
      ),
      GoRoute(
        name: AppRoutes.ordersName,
        path: AppRoutes.orders,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        name: AppRoutes.orderSuccessName,
        path: AppRoutes.orderSuccess,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['orderId'];
          final isPayWay = extra?['isPayWay'] as bool? ?? false;
          return OrderSuccessScreen(
            orderId: orderId,
            isPayWay: isPayWay,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.avatarCustomizerName,
        path: AppRoutes.avatarCustomizer,
        builder: (context, state) => const AvatarCustomizerScreen(),
      ),
      GoRoute(
        name: AppRoutes.aiAssistantName,
        path: AppRoutes.aiAssistant,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AiAssistantScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: FadeTransition(
                  opacity: curvedAnimation,
                  child: child,
                ),
              );
            },
          );
        },
      ),

      // ── Stateful Tab Shell with 4 Persistent Branches ───────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNav(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.homeName,
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Explore / Categories
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.categoriesName,
                path: AppRoutes.categories,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final categorySlug = extra?['categorySlug'] as String?;
                  return AllProductsScreen(initialCategorySlug: categorySlug);
                },
              ),
            ],
          ),

          // Branch 2: Wishlist
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.wishlistName,
                path: AppRoutes.wishlist,
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.profileName,
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
