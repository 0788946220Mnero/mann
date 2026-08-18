import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/order_status.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/restaurant_service.dart';
import '../../core/theme/app_theme.dart';
import '../permissions/permission_service.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenOrders});
  final void Function(OrderStatus? filter) onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>();
    final user = context.watch<AuthService>().user;

    return RefreshIndicator(
      onRefresh: () => orders.fetchOrders(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _RestaurantStatusCard(canToggle: PermissionService.can(user, Permission.toggleRestaurantStatus)),
          const SizedBox(height: 18),

          const Text('  الطلبات الحالية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _CountCard(label: 'طلبات جديدة', count: orders.newCount,
                  color: AppColors.statusNew, icon: Icons.fiber_new,
                  onTap: () => onOpenOrders(OrderStatus.pending)),
              _CountCard(label: 'قيد التحضير', count: orders.preparingCount,
                  color: AppColors.statusPreparing, icon: Icons.soup_kitchen,
                  onTap: () => onOpenOrders(OrderStatus.preparing)),
              _CountCard(label: 'جاهزة', count: orders.readyCount,
                  color: AppColors.statusReady, icon: Icons.check_circle_outline,
                  onTap: () => onOpenOrders(OrderStatus.ready)),
              _CountCard(label: 'مكتملة', count: orders.completedCount,
                  color: AppColors.statusDone, icon: Icons.done_all,
                  onTap: () => onOpenOrders(OrderStatus.delivered)),
              _CountCard(label: 'ملغاة', count: orders.cancelledCount,
                  color: AppColors.statusCancelled, icon: Icons.cancel_outlined,
                  onTap: () => onOpenOrders(OrderStatus.cancelled)),
            ],
          ),

          if (PermissionService.can(user, Permission.viewSales)) ...[
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen())),
                child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.gold, size: 30),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مبيعات اليوم',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                        const SizedBox(height: 4),
                        Text('${orders.todaySales.toStringAsFixed(2)} د.أ',
                            style: const TextStyle(
                                color: AppColors.gold, fontSize: 21, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_left, color: AppColors.textMuted),
                  ],
                ),
              ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label, required this.count,
    required this.color, required this.icon, required this.onTap,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Text('$count',
                style: TextStyle(color: color, fontSize: 27, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _RestaurantStatusCard extends StatelessWidget {
  const _RestaurantStatusCard({required this.canToggle});
  final bool canToggle;

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RestaurantService>();
    final open = r.isOpen;
    final color = open ? AppColors.statusReady : AppColors.statusNew;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: Row(
        children: [
          Icon(open ? Icons.storefront : Icons.do_not_disturb_on_outlined, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label,
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                if (r.busyUntil != null)
                  Text('حتى ${TimeOfDay.fromDateTime(r.busyUntil!).format(context)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (canToggle)
            TextButton(
              onPressed: r.loading
                  ? null
                  : () => r.setMode(open ? 'stopped' : 'open'),
              child: Text(open ? 'إغلاق' : 'فتح',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
