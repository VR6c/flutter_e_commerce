import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../providers/bottom_nav_scroll_provider.dart';

class ScaffoldWithBottomNav extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  @override
  ConsumerState<ScaffoldWithBottomNav> createState() =>
      _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends ConsumerState<ScaffoldWithBottomNav> {
  DateTime? _lastTapTime;
  int? _lastTappedIndex;

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final isSameIndex = index == widget.navigationShell.currentIndex;
    final isMultiClick =
        _lastTappedIndex == index &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 600);

    _lastTapTime = now;
    _lastTappedIndex = index;

    widget.navigationShell.goBranch(index, initialLocation: isSameIndex);

    // If clicking the current tab or multi-clicking the same tab, request scroll to top
    if (isSameIndex || isMultiClick) {
      ref.read(bottomNavScrollProvider.notifier).requestScrollToTop(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;

    final barBg = isDark ? const Color(0xFF131D38) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Main Bar Container
          Container(
            height: 64 + bottomInset,
            padding: EdgeInsets.only(
              bottom: bottomInset > 0 ? bottomInset - 4 : 0,
            ),
            decoration: BoxDecoration(
              color: barBg,
              border: Border(top: BorderSide(color: borderColor, width: 1.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left 2 items
                Expanded(
                  child: _BottomNavItem(
                    index: 0,
                    isSelected: currentIndex == 0,
                    inactiveIcon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: l10n.navHome,
                    onTap: () => _onItemTapped(0),
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    index: 1,
                    isSelected: currentIndex == 1,
                    inactiveIcon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront_rounded,
                    label: l10n.navProducts,
                    onTap: () => _onItemTapped(1),
                    theme: theme,
                    isDark: isDark,
                  ),
                ),

                // Center Spacer for elevated Cart button
                const SizedBox(width: 68),

                // Right 2 items
                Expanded(
                  child: _BottomNavItem(
                    index: 2,
                    isSelected: currentIndex == 2,
                    inactiveIcon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                    label: l10n.navWishlist,
                    onTap: () => _onItemTapped(2),
                    theme: theme,
                    isDark: isDark,
                    badge: Consumer(
                      builder: (context, ref, _) {
                        final count = ref.watch(wishlistCountProvider);
                        if (count == 0) return const SizedBox.shrink();
                        return Positioned(
                          top: -3,
                          right: -7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: barBg, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    index: 3,
                    isSelected: currentIndex == 3,
                    inactiveIcon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: l10n.navProfile,
                    onTap: () => _onItemTapped(3),
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          // Elevated Center Floating Cart Action Button matching mockup
          Positioned(
            top: -18,
            child: _CenterFloatingCartButton(
              barBg: barBg,
              isDark: isDark,
              theme: theme,
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/cart');
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A modern interactive bottom navigation item with tactile scale feedback and active dot
class _BottomNavItem extends StatefulWidget {
  final int index;
  final bool isSelected;
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;
  final Widget? badge;

  const _BottomNavItem({
    required this.index,
    required this.isSelected,
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    required this.theme,
    required this.isDark,
    this.badge,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.theme.colorScheme.primary;
    final inactiveColor = widget.isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.isSelected ? widget.activeIcon : widget.inactiveIcon,
                    key: ValueKey<bool>(widget.isSelected),
                    color: widget.isSelected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                ),
                if (widget.badge != null) widget.badge!,
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: widget.isSelected ? activeColor : inactiveColor,
                fontSize: 11.5,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                letterSpacing: 0,
                height: 1.25,
              ),
              child: Text(widget.label),
            ),
            const SizedBox(height: 2),
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: widget.isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isSelected ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The prominent center floating circular cart button from the reference UI
class _CenterFloatingCartButton extends StatefulWidget {
  final Color barBg;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _CenterFloatingCartButton({
    required this.barBg,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_CenterFloatingCartButton> createState() =>
      _CenterFloatingCartButtonState();
}

class _CenterFloatingCartButtonState extends State<_CenterFloatingCartButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF23AA49);
    const secondaryGreen = Color(0xFF1EA043);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.barBg,
            boxShadow: [
              // Outer halo shadow
              BoxShadow(
                color: primaryGreen.withValues(
                  alpha: widget.isDark ? 0.45 : 0.35,
                ),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4.5), // Outer ring matching bottom bar
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF29B850), secondaryGreen],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.white,
                  size: 25,
                ),
                // Isolated Consumer: only badge rebuilds on cart change
                Consumer(
                  builder: (context, ref, _) {
                    final cartCount = ref.watch(cartItemsCountProvider);
                    if (cartCount == 0) return const SizedBox.shrink();

                    return Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        child: Text(
                          cartCount > 99 ? '99+' : '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
