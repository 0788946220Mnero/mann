import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../theme/app_theme.dart';

Color statusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
    case OrderStatus.newOrder:
      return AppColors.statusNew;
    case OrderStatus.preparing:
      return AppColors.statusPreparing;
    case OrderStatus.ready:
    case OrderStatus.outForDelivery:
      return AppColors.statusReady;
    case OrderStatus.delivered:
      return AppColors.statusDone;
    case OrderStatus.cancelled:
      return AppColors.statusCancelled;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.5)),
      ),
      child: Text(status.label,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
