import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/models/order.dart';
import '../../core/models/order_status.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_chip.dart';
import '../permissions/permission_service.dart';
import 'delivery_info_card.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<OrderService>();
    final user = context.watch<AuthService>().user;
    final order = service.byId(orderId);

    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('الطلب غير موجود', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final transitions = PermissionService.allowedTransitions(user, order.status);

    return Scaffold(
      appBar: AppBar(title: Text('طلب #${order.orderNumber}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          Row(
            children: [
              StatusChip(order.status),
              const Spacer(),
              Text(DateFormat('yyyy/MM/dd — hh:mm a', 'ar').format(order.createdAt),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 14),

          _Section(
            title: 'معلومات الزبون',
            icon: Icons.person_outline,
            children: [
              _row('الاسم', order.customerName),
              _row('الهاتف', '${order.phone}${order.phoneVerified ? '  ✓ موثّق' : ''}'),
              _row('نوع الطلب', order.orderTypeLabel),
              if (order.isDelivery && order.address.isNotEmpty) _row('العنوان', order.address),
              if (order.notes.isNotEmpty) _row('ملاحظات الزبون', order.notes),
            ],
          ),

          DeliveryInfoCard(order: order),

          _Section(
            title: 'المنتجات',
            icon: Icons.fastfood_outlined,
            children: order.items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${it.name} × ${it.quantity}',
                            style: const TextStyle(
                                color: AppColors.textMain, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      ),
                      Text('${it.lineTotal.toStringAsFixed(2)} د.أ',
                          style: const TextStyle(color: AppColors.gold, fontSize: 14)),
                    ],
                  ),
                  if (it.addons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, right: 8),
                      child: Text('إضافات: ${it.addons.join('، ')}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    ),
                  if (it.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 8),
                      child: Text('ملاحظة: ${it.notes}',
                          style: const TextStyle(color: AppColors.statusPreparing, fontSize: 12.5)),
                    ),
                ],
              ),
            )).toList(),
          ),

          _Section(
            title: 'الحساب',
            icon: Icons.receipt_long_outlined,
            children: [
              _row('قيمة المنتجات', '${order.itemsTotal.toStringAsFixed(2)} د.أ'),
              _row('خدمة التوصيل', '${order.deliveryFee.toStringAsFixed(2)} د.أ'),
              _row('طريقة الدفع', order.paymentLabel),
              const Divider(height: 20),
              Row(
                children: [
                  const Text('الإجمالي',
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text('${order.total.toStringAsFixed(2)} د.أ',
                      style: const TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),

          if (transitions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Text('لا توجد إجراءات متاحة لهذا الطلب',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            )
          else ...[
            const SizedBox(height: 6),
            const Text('  إجراءات الطلب',
                style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...transitions.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t == OrderStatus.cancelled
                            ? AppColors.statusCancelled
                            : statusColor(t),
                      ),
                      icon: Icon(_iconFor(t), size: 18),
                      label: Text(_actionLabel(t)),
                      onPressed: () => _confirmAndApply(context, order, t),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.newOrder: return Icons.check_circle_outline;
      case OrderStatus.preparing: return Icons.soup_kitchen;
      case OrderStatus.ready: return Icons.done;
      case OrderStatus.outForDelivery: return Icons.delivery_dining;
      case OrderStatus.delivered: return Icons.done_all;
      case OrderStatus.cancelled: return Icons.close;
      default: return Icons.arrow_forward;
    }
  }

  static String _actionLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.newOrder: return 'قبول الطلب';
      case OrderStatus.preparing: return 'بدء التحضير';
      case OrderStatus.ready: return 'جاهز';
      case OrderStatus.outForDelivery: return 'خرج للتوصيل';
      case OrderStatus.delivered: return 'تم التسليم';
      case OrderStatus.cancelled: return 'إلغاء الطلب';
      default: return s.label;
    }
  }

  Future<void> _confirmAndApply(BuildContext context, Order order, OrderStatus target) async {
    if (target == OrderStatus.cancelled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('إلغاء الطلب'),
          content: Text('هل تريد إلغاء الطلب #${order.orderNumber}؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('تراجع')),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('إلغاء الطلب', style: TextStyle(color: AppColors.statusNew)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<OrderService>().updateStatus(order.id, target);
      messenger.showSnackBar(SnackBar(content: Text('تم تحديث الطلب: ${target.label}')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  static Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 13.5)),
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 17, color: AppColors.gold),
              const SizedBox(width: 7),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14.5)),
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
