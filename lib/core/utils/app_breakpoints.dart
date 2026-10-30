import 'package:flutter/material.dart';

class AppBreakpoints {
  AppBreakpoints._();

  /// Minimum width (dp) for a tablet-sized screen.
  static const double tablet = 600;

  /// Minimum width (dp) for a desktop-sized screen.
  static const double desktop = 1024;

  /// Returns `true` when [width] is in the mobile range (< 600 dp).
  static bool isMobile(double width) => width < tablet;

  /// Returns `true` when [width] is in the tablet range (600 – 1023 dp).
  static bool isTablet(double width) => width >= tablet && width < desktop;

  /// Returns `true` when [width] is in the desktop range (≥ 1024 dp).
  static bool isDesktop(double width) => width >= desktop;

  /// Returns the current [ScreenType] for the given [context].
  static ScreenType screenTypeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return ScreenType.desktop;
    if (width >= tablet) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  /// Falls back to [tablet] → [mobile] when larger values are `null`.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final type = screenTypeOf(context);
    return switch (type) {
      ScreenType.desktop => desktop ?? tablet ?? mobile,
      ScreenType.tablet => tablet ?? mobile,
      ScreenType.mobile => mobile,
    };
  }
}

/// Enum representing the three responsive tiers.
enum ScreenType {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == ScreenType.mobile;
  bool get isTablet => this == ScreenType.tablet;
  bool get isDesktop => this == ScreenType.desktop;
}

extension ResponsiveContext on BuildContext {
  /// Width of the current screen.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Height of the current screen.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// The resolved [ScreenType] for this context.
  ScreenType get screenType => AppBreakpoints.screenTypeOf(this);

  bool get isMobile => screenType.isMobile;
  bool get isTablet => screenType.isTablet;
  bool get isDesktop => screenType.isDesktop;

  /// Picks a value by screen type with graceful fall-back.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) =>
      AppBreakpoints.value(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}

///
/// If [tablet] or [desktop] are omitted the next smaller layout is shown.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Layout rendered on phones (width < 600 dp).
  final Widget mobile;

  /// Layout rendered on tablets (600 ≤ width < 1024 dp).
  /// Falls back to [mobile] when `null`.
  final Widget? tablet;

  /// Layout rendered on desktops (width ≥ 1024 dp).
  /// Falls back to [tablet] → [mobile] when `null`.
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return switch (context.screenType) {
      ScreenType.desktop => desktop ?? tablet ?? mobile,
      ScreenType.tablet => tablet ?? mobile,
      ScreenType.mobile => mobile,
    };
  }
}

/// A builder variant of [ResponsiveLayout] that exposes the [ScreenType]
/// and screen dimensions to the child builder.
///
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ScreenType screenType, Size size)
  builder;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return builder(context, AppBreakpoints.screenTypeOf(context), size);
  }
}
