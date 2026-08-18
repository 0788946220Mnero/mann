/// إعدادات التطبيق العامة.
/// يتصل التطبيق بنفس الـ Backend الحالي لموقع ديار الأنباط — لا خادم جديد.
class AppConfig {
  AppConfig._();

  /// عنوان الـ Backend الحالي (نفسه المستخدم في الموقع ولوحة التحكم القديمة).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://n-production-78f4.up.railway.app',
  );

  /// عنوان WebSocket للطلبات الفورية (يُفعَّل عند توفّره في الخادم).
  /// إن كان فارغاً يعمل التطبيق تلقائياً بنظام الاستطلاع (Polling).
  static const String wsUrl = String.fromEnvironment('WS_URL', defaultValue: '');

  /// مدة الاستطلاع الاحتياطي لجلب الطلبات الجديدة.
  static const Duration pollInterval = Duration(seconds: 8);

  static const String appName = 'ديار الأنباط';
  static const String appSubtitle = 'تطبيق الإدارة';
}
