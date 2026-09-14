import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a scroll-to-top event requested by navigation taps.
class BottomNavScrollEvent {
  final int tabIndex;
  final int triggerCount;

  const BottomNavScrollEvent({
    required this.tabIndex,
    required this.triggerCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BottomNavScrollEvent &&
          runtimeType == other.runtimeType &&
          tabIndex == other.tabIndex &&
          triggerCount == other.triggerCount;

  @override
  int get hashCode => tabIndex.hashCode ^ triggerCount.hashCode;
}

/// Notifier that publishes scroll-to-top requests for tabs.
class BottomNavScrollNotifier extends StateNotifier<BottomNavScrollEvent> {
  BottomNavScrollNotifier()
      : super(const BottomNavScrollEvent(tabIndex: -1, triggerCount: 0));

  /// Requests the tab at [tabIndex] to scroll to the top.
  void requestScrollToTop(int tabIndex) {
    state = BottomNavScrollEvent(
      tabIndex: tabIndex,
      triggerCount: state.triggerCount + 1,
    );
  }
}

/// Provider for tab scroll-to-top events triggered from the bottom nav bar.
final bottomNavScrollProvider =
    StateNotifierProvider<BottomNavScrollNotifier, BottomNavScrollEvent>((ref) {
  return BottomNavScrollNotifier();
});
