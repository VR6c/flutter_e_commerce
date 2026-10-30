import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import 'order_detail_bottom_sheet.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final Order? order;
  final dynamic orderId;

  const OrderDetailScreen({
    super.key,
    this.order,
    this.orderId,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null && widget.orderId != null) {
      _fetchOrder();
    }
  }

  Future<void> _fetchOrder() async {
    final parsedId = int.tryParse('${widget.orderId}');
    if (parsedId == null) {
      setState(() => _error = 'Invalid Order ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fetched =
          await ref.read(orderRepositoryProvider).fetchOrderDetail(parsedId);
      if (mounted) {
        setState(() {
          _order = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
        title: Text(
          _order != null
              ? l10n.orderNumber(_order!.id)
              : (widget.orderId != null
                  ? l10n.orderNumber(widget.orderId)
                  : l10n.orderDetails),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.orderId != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _fetchOrder,
            ),
        ],
      ),
      body: _buildBody(theme, isDark, l10n),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark, AppLocalizations l10n) {
    if (_isLoading) {
      return _buildSkeleton(theme, isDark);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 52, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.couldNotLoadOrders,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchOrder,
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Center(
        child: Text(
          l10n.noOrders,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
      );
    }

    return OrderDetailContentView(
      order: _order!,
      isBottomSheet: false,
    );
  }

  Widget _buildSkeleton(ThemeData theme, bool isDark) {
    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
