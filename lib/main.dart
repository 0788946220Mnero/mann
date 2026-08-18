import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/app_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/order_service.dart';
import 'core/services/restaurant_service.dart';
import 'core/services/stats_service.dart';
import 'core/services/user_service.dart';
import 'core/services/delivery_service.dart';
import 'core/services/device_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

  final notifications = NotificationService();
  await notifications.init();

  final auth = AuthService();
  await auth.restoreSession();

  runApp(DiyarAdminApp(auth: auth, notifications: notifications));
}

class DiyarAdminApp extends StatelessWidget {
  const DiyarAdminApp({super.key, required this.auth, required this.notifications});
  final AuthService auth;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    final api = auth.api;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: notifications),
        ChangeNotifierProvider(
          create: (_) => OrderService(api: api, notifications: notifications),
        ),
        ChangeNotifierProvider(create: (_) => RestaurantService(api: api)),
        ChangeNotifierProvider(create: (_) => StatsService(api: api)),
        ChangeNotifierProvider(create: (_) => UserService(api: api)),
        ChangeNotifierProvider(create: (_) => DeliveryService(api: api)),
        ChangeNotifierProvider(create: (_) => DeviceService(api: api)),
        Provider<ApiClient>.value(value: api),
      ],
      child: MaterialApp(
        title: '${AppConfig.appName} — ${AppConfig.appSubtitle}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // دعم RTL كامل
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: Consumer<AuthService>(
          builder: (_, a, __) => a.isLoggedIn ? const MainShell() : const LoginScreen(),
        ),
      ),
    );
  }
}
