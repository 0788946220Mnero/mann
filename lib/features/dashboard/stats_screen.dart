import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/stats_service.dart';
import '../../core/theme/app_theme.dart';

/// لوحة الإحصائيات — بيانات حقيقية من الخادم (لا بيانات وهمية).
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<StatsService>().load());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StatsService>();
    final st = s.stats;

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: RefreshIndicator(
        onRefresh: () => s.load(),
        child: s.loading && st.todayOrders == 0 && st.topProducts.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                children: [
                  if (s.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(s.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.statusNew, fontSize: 13)),
                    ),

                  const Text('  اليوم',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _StatCard(
                          label: 'طلبات اليوم',
                          value: '${st.todayOrders}',
                          icon: Icons.receipt_long,
                          color: AppColors.statusDone),
                      _StatCard(
                          label: 'مبيعات اليوم',
                          value: '${st.todaySales.toStringAsFixed(2)} د.أ',
                          icon: Icons.payments_outlined,
                          color: AppColors.gold),
                      _StatCard(
                          label: 'بانتظار القبول',
                          value: '${st.pendingOrders}',
                          icon: Icons.hourglass_empty,
                          color: AppColors.statusNew),
                      _StatCard(
                          label: 'متوسط قيمة الطلب',
                          value: '${st.avgOrderValue.toStringAsFixed(2)} د.أ',
                          icon: Icons.trending_up,
                          color: AppColors.statusReady),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text('  التوصيل اليوم',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _StatCard(
                          label: 'طلبات التوصيل',
                          value: '${st.deliveryCount}',
                          icon: Icons.delivery_dining,
                          color: AppColors.statusDone),
                      _StatCard(
                          label: 'رسوم التوصيل',
                          value: '${st.deliveryFeesTotal.toStringAsFixed(2)} د.أ',
                          icon: Icons.route,
                          color: AppColors.gold),
                      _StatCard(
                          label: 'طلبات الاستلام',
                          value: '${st.pickupCount}',
                          icon: Icons.storefront,
                          color: AppColors.statusReady),
                      _StatCard(
                          label: 'متوسط المسافة',
                          value: st.avgDeliveryDistanceKm == null
                              ? '—'
                              : '${st.avgDeliveryDistanceKm!.toStringAsFixed(1)} كم',
                          icon: Icons.straighten,
                          color: AppColors.statusPreparing),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text('  الشهر',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.gold, size: 28),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مبيعات الشهر',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                              const SizedBox(height: 4),
                              Text('${st.monthlySales.toStringAsFixed(2)} د.أ',
                                  style: const TextStyle(
                                      color: AppColors.gold, fontSize: 21, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('  أكثر المنتجات طلباً',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (st.topProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: Text('لا توجد بيانات بعد',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                    )
                  else
                    ...st.topProducts.asMap().entries.map((e) {
                      final maxQty = st.topProducts.first.quantity;
                      final ratio = maxQty == 0 ? 0.0 : e.value.quantity / maxQty;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.gold.withOpacity(.16),
                                    child: Text('${e.key + 1}',
                                        style: const TextStyle(
                                            color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(e.value.name,
                                        style: const TextStyle(color: AppColors.textMain, fontSize: 14)),
                                  ),
                                  Text('${e.value.quantity}',
                                      style: const TextStyle(
                                          color: AppColors.gold, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 5,
                                  backgroundColor: AppColors.surfaceAlt,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 21),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value,
                style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.bold)),
          ),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
