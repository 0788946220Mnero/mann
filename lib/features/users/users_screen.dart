import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/models/app_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_theme.dart';

/// إدارة مستخدمي الإدارة — إنشاء حسابات الكاشير والمطبخ والمديرين.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<UserService>().load());
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<UserService>();
    final me = context.watch<AuthService>().user;
    final isAdmin = me?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.red,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('مستخدم جديد'),
              onPressed: () => _openForm(context),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => service.load(),
        child: service.loading && service.users.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : service.error != null
                ? Center(child: Text(service.error!, style: const TextStyle(color: AppColors.statusNew)))
                : service.users.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 100),
                        Icon(Icons.group_outlined, size: 54, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Center(child: Text('لا يوجد مستخدمون',
                            style: TextStyle(color: AppColors.textMuted))),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 90),
                        itemCount: service.users.length,
                        itemBuilder: (_, i) {
                          final u = service.users[i];
                          final isMe = u.id == me?.id;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _roleColor(u.role).withOpacity(.18),
                                child: Text(
                                  u.name.isNotEmpty ? u.name.characters.first : '؟',
                                  style: TextStyle(
                                      color: _roleColor(u.role), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(u.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14.5)),
                                  ),
                                  if (isMe)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Text('(أنت)',
                                          style: TextStyle(color: AppColors.gold, fontSize: 11)),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _roleColor(u.role).withOpacity(.14),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(u.role.label,
                                          style: TextStyle(color: _roleColor(u.role), fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('@${u.username}',
                                        style: const TextStyle(
                                            color: AppColors.textMuted, fontSize: 11.5)),
                                    if (!u.isActive) ...[
                                      const SizedBox(width: 8),
                                      const Text('معطّل',
                                          style: TextStyle(color: AppColors.statusNew, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: isAdmin
                                  ? PopupMenuButton<String>(
                                      color: AppColors.surface,
                                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                                      onSelected: (v) => _onAction(context, v, u),
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                        PopupMenuItem(
                                            value: 'toggle',
                                            child: Text(u.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب')),
                                        if (!isMe)
                                          const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('حذف',
                                                  style: TextStyle(color: AppColors.statusNew))),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  static Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.admin: return AppColors.gold;
      case UserRole.manager: return AppColors.statusDone;
      case UserRole.cashier: return AppColors.statusReady;
      case UserRole.employee: return AppColors.statusPreparing;
    }
  }

  Future<void> _onAction(BuildContext context, String action, AppUser u) async {
    final service = context.read<UserService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (action == 'edit') {
        await _openForm(context, existing: u);
      } else if (action == 'toggle') {
        await service.update(u.id, isActive: !u.isActive);
        messenger.showSnackBar(
            SnackBar(content: Text(u.isActive ? 'تم تعطيل الحساب' : 'تم تفعيل الحساب')));
      } else if (action == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('حذف المستخدم'),
            content: Text('حذف ${u.name} نهائياً؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('تراجع')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('حذف', style: TextStyle(color: AppColors.statusNew))),
            ],
          ),
        );
        if (ok == true) {
          await service.remove(u.id);
          messenger.showSnackBar(const SnackBar(content: Text('تم حذف المستخدم')));
        }
      }
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openForm(BuildContext context, {AppUser? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final username = TextEditingController(text: existing?.username ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final password = TextEditingController();
    UserRole role = existing?.role ?? UserRole.cashier;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 18, right: 18, top: 20,
            bottom: MediaQuery.of(c).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing == null ? 'مستخدم جديد' : 'تعديل المستخدم',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                TextField(controller: name,
                    decoration: const InputDecoration(hintText: 'الاسم الكامل')),
                const SizedBox(height: 10),
                TextField(controller: username,
                    decoration: const InputDecoration(hintText: 'اسم المستخدم (بالإنجليزية)')),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: existing == null
                        ? 'كلمة المرور (6 أحرف على الأقل)'
                        : 'كلمة مرور جديدة (اتركها فارغة للإبقاء)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'رقم الهاتف (اختياري)')),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('الدور والصلاحيات',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: UserRole.values.map((r) => ChoiceChip(
                    label: Text(r.label),
                    selected: role == r,
                    onSelected: (_) => setSheet(() => role = r),
                    selectedColor: AppColors.gold.withOpacity(.22),
                    backgroundColor: AppColors.surfaceAlt,
                    side: BorderSide(color: role == r ? AppColors.gold : AppColors.border),
                    labelStyle: TextStyle(
                        color: role == r ? AppColors.gold : AppColors.textMuted, fontSize: 12.5),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(c);
                    final service = context.read<UserService>();
                    try {
                      if (existing == null) {
                        await service.create(
                          name: name.text.trim(),
                          username: username.text.trim(),
                          password: password.text,
                          role: role,
                          phone: phone.text.trim(),
                        );
                      } else {
                        await service.update(
                          existing.id,
                          name: name.text.trim(),
                          username: username.text.trim(),
                          password: password.text,
                          role: role,
                          phone: phone.text.trim(),
                        );
                      }
                      nav.pop();
                      messenger.showSnackBar(SnackBar(
                          content: Text(existing == null ? 'تم إنشاء المستخدم' : 'تم حفظ التعديلات')));
                    } on ApiException catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  child: Text(existing == null ? 'إنشاء المستخدم' : 'حفظ التعديلات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
