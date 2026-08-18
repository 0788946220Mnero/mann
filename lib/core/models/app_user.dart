import 'dart:convert';

/// أدوار الإدارة — مطابقة للـ Backend: admin | manager | cashier | employee
enum UserRole {
  admin, manager, cashier, employee;

  static UserRole fromApi(String? v) {
    switch (v) {
      case 'admin': return UserRole.admin;
      case 'manager': return UserRole.manager;
      case 'cashier': return UserRole.cashier;
      default: return UserRole.employee;
    }
  }

  String get apiValue => name;

  String get label {
    switch (this) {
      case UserRole.admin: return 'مدير النظام';
      case UserRole.manager: return 'مدير';
      case UserRole.cashier: return 'كاشير';
      case UserRole.employee: return 'موظف';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String username;
  final UserRole role;
  final String phone;
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.phone = '',
    this.isActive = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        name: (j['name'] ?? '') as String,
        username: (j['username'] ?? '') as String,
        role: UserRole.fromApi(j['role'] as String?),
        phone: (j['phone'] ?? '') as String,
        isActive: j['isActive'] != false,
      );

  Map<String, dynamic> toJson() =>
      {'_id': id, 'name': name, 'username': username, 'role': role.apiValue,
       'phone': phone, 'isActive': isActive};

  String encode() => jsonEncode(toJson());
  static AppUser decode(String s) => AppUser.fromJson(jsonDecode(s));
}
