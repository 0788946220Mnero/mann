import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/stats_screen.dart';
import '../orders/order_history_screen.dart';
import '../users/users_screen.dart';
import '../restaurant/delivery_settings_screen.dart';
import '../permissions/permission_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final notif = context.watch<NotificationService>();
    final user = auth.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.gold.withOpacity(.18),
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name.characters.first : '؟',
                    style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—',
                          style: const TextStyle(
                              color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(user?.role.label ?? '',
                          style: const TextStyle(color: AppColors.gold, fontSize: 12.5)),
                      Text('@${user?.username ?? ''}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.history, color: AppColors.gold),
            title: const Text('سجل الطلبات', style: TextStyle(fontSize: 14.5)),
            subtitle: const Text('الطلبات السابقة مع البحث والتصفية بالتاريخ',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
        ),
        if (PermissionService.can(user, Permission.viewSales)) ...[
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.gold),
              title: const Text('الإحصائيات', style: TextStyle(fontSize: 14.5)),
              subtitle: const Text('المبيعات وأكثر المنتجات طلباً',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen())),
            ),
          ),
        ],
        if (PermissionService.can(user, Permission.viewDeliverySettings)) ...[
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.delivery_dining, color: AppColors.gold),
              title: const Text('إعدادات التوصيل', style: TextStyle(fontSize: 14.5)),
              subtitle: const Text('موقع المطعم ورسوم التوصيل وتفعيل الخدمة',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeliverySettingsScreen())),
            ),
          ),
        ],
        if (PermissionService.can(user, Permission.manageUsers)) ...[
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.group_outlined, color: AppColors.gold),
              title: const Text('المستخدمون', style: TextStyle(fontSize: 14.5)),
              subtitle: const Text('إنشاء حسابات الكاشير والمطبخ وإدارة الصلاحيات',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UsersScreen())),
            ),
          ),
        ],
        const SizedBox(height: 10),

        Card(
          margin: EdgeInsets.zero,
          child: SwitchListTile(
            value: notif.soundEnabled,
            onChanged: notif.setSoundEnabled,
            activeColor: AppColors.gold,
            title: const Text('صوت الطلبات الجديدة', style: TextStyle(fontSize: 14.5)),
            subtitle: const Text('تنبيه صوتي عند وصول طلب جديد',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            secondary: const Icon(Icons.volume_up_outlined, color: AppColors.gold),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.gold),
            title: const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 14.5)),
            trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
            onTap: () => _changePasswordDialog(context),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.logout, color: AppColors.statusNew),
            title: const Text('تسجيل الخروج',
                style: TextStyle(fontSize: 14.5, color: AppColors.statusNew)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل تريد الخروج من التطبيق؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('تراجع')),
                    TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('خروج', style: TextStyle(color: AppColors.statusNew))),
                  ],
                ),
              );
              if (ok == true) await auth.logout();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _changePasswordDialog(BuildContext context) async {
    final current = TextEditingController();
    final newPass = TextEditingController();
    final confirm = TextEditingController();

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: current, obscureText: true,
                decoration: const InputDecoration(hintText: 'كلمة المرور الحالية')),
            const SizedBox(height: 10),
            TextField(controller: newPass, obscureText: true,
                decoration: const InputDecoration(hintText: 'كلمة المرور الجديدة')),
            const SizedBox(height: 10),
            TextField(controller: confirm, obscureText: true,
                decoration: const InputDecoration(hintText: 'تأكيد كلمة المرور')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('تراجع')),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(c);
              try {
                await context.read<AuthService>().changePassword(
                      current: current.text, newPassword: newPass.text, confirm: confirm.text,
                    );
                nav.pop();
                messenger.showSnackBar(
                    const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
              } on ApiException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            child: const Text('حفظ', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}
