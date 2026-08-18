import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    final items = service.items;

    if (items.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.notifications_none, size: 54, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text('لا توجد إشعارات', style: TextStyle(color: AppColors.textMuted)),
        ]),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: service.markAllRead,
            icon: const Icon(Icons.done_all, size: 17, color: AppColors.gold),
            label: const Text('تعليم الكل كمقروء', style: TextStyle(color: AppColors.gold)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final n = items[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.circle,
                      size: 10, color: n.read ? AppColors.textMuted : AppColors.statusNew),
                  title: Text(n.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(n.body, style: const TextStyle(fontSize: 12.5)),
                  trailing: Text(DateFormat('hh:mm a', 'ar').format(n.at),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
