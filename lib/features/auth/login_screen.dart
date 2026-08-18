import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await context.read<AuthService>().login(_username.text, _password.text);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذّر تسجيل الدخول. حاول مجدداً.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthService>().loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 84, height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: const Icon(Icons.restaurant_menu, color: AppColors.gold, size: 40),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'تسجيل دخول الإدارة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم المستخدم' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'أدخل كلمة المرور' : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusNew.withOpacity(.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.statusNew, fontSize: 13)),
                      ),
                    ],

                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('تسجيل الدخول'),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'هذا التطبيق مخصّص لطاقم الإدارة فقط',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
