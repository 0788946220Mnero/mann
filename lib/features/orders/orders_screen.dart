import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/order.dart';
import '../../core/models/order_status.dart';
import '../../core/services/order_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_chip.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialFilter});
  final OrderStatus? initialFilter;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _filter;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant OrdersScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialFilter != old.initialFilter) {
      setState(() => _filter = widget.initialFilter);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Order> _apply(List<Order> all) {
    var list = all;
    if (_filter != null) {
      if (_filter == OrderStatus.pending) {
        list = list.where((o) =>
            o.status == OrderStatus.pending || o.status == OrderStatus.newOrder).toList();
      } else if (_filter == OrderStatus.ready) {
        list = list.where((o) =>
            o.status == OrderStatus.ready || o.status == OrderStatus.outForDelivery).toList();
      } else {
        list = list.where((o) => o.status == _filter).toList();
      }
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.trim();
      list = list.where((o) =>
          o.orderNumber.contains(q) ||
          o.customerName.contains(q) ||
          o.phone.contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<OrderService>();
    final list = _apply(service.orders);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الطلب أو اسم الزبون أو الهاتف',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      }),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('الكل', null),
              _chip('جديد', OrderStatus.pending),
              _chip('قيد التحضير', OrderStatus.preparing),
              _chip('جاهز', OrderStatus.ready),
              _chip('مكتمل', OrderStatus.delivered),
              _chip('ملغي', OrderStatus.cancelled),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => service.fetchOrders(),
            child: service.loading && service.orders.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : list.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 90),
                        Icon(Icons.receipt_long, size: 54, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Center(child: Text('لا توجد طلبات مطابقة',
                            style: TextStyle(color: AppColors.textMuted))),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _OrderCard(order: list[i]),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, OrderStatus? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.gold.withOpacity(.22),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
        labelStyle: TextStyle(
          color: selected ? AppColors.gold : AppColors.textMuted,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a', 'ar').format(order.createdAt);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${order.orderNumber}',
                      style: const TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  StatusChip(order.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(order.customerName,
                        style: const TextStyle(color: AppColors.textMain, fontSize: 14)),
                  ),
                  if (order.phoneVerified)
                    const Icon(Icons.verified, size: 15, color: AppColors.statusReady),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(order.phone,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (order.isDelivery ? AppColors.statusDone : AppColors.statusReady)
                          .withOpacity(.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.isDelivery ? '🚗 توصيل' : '🏪 استلام من المطعم',
                      style: TextStyle(
                        color: order.isDelivery ? AppColors.statusDone : AppColors.statusReady,
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                  const Spacer(),
                  Text('${order.total.toStringAsFixed(2)} د.أ',
                      style: const TextStyle(
                          color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
