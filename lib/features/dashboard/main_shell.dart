import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_config.dart';
import '../../core/models/order_status.dart';
import '../../core/storage/token_storage.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/restaurant_service.dart';
import '../../core/services/delivery_service.dart';
import '../../core/theme/app_theme.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';

/// الهيكل الرئيسي بعد تسجيل الدخول: تنقّل سفلي واضح وسريع.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  OrderStatus? _ordersFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<RestaurantService>().load();
      context.read<DeliveryService>().load(); // موقع المطعم لخريطة تفاصيل الطلب

      // رمز الدخول مطلوب لمصادقة WebSocket على الخادم
      final token = await TokenStorage().accessToken;
      if (mounted) context.read<OrderService>().start(token);
    });
  }

  void _openOrders(OrderStatus? filter) {
    setState(() {
      _ordersFilter = filter;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationService>();

    final titles = ['الرئيسية', 'الطلبات', 'الإشعارات', 'الإعدادات'];
    final pages = [
      DashboardScreen(onOpenOrders: _openOrders),
      OrdersScreen(initialFilter: _ordersFilter),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(titles[_index], style: const TextStyle(fontSize: 16)),
            const Text(AppConfig.appName,
                style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => context.read<OrderService>().fetchOrders(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          if (i == 1) _ordersFilter = _ordersFilter;
        }),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.gold),
              label: 'الرئيسية'),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: AppColors.gold),
              label: 'الطلبات'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notif.unreadCount > 0,
              label: Text('${notif.unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications, color: AppColors.gold),
            label: 'الإشعارات',
          ),
          const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.gold),
              label: 'الإعدادات'),
        ],
      ),
    );
  }
}
