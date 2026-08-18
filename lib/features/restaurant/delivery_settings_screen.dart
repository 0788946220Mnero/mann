import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/models/delivery_settings.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/delivery_service.dart';
import '../../core/theme/app_theme.dart';
import '../permissions/permission_service.dart';

/// إعدادات التوصيل — تُحفظ في الخادم مباشرة وتؤثر على موقع الزبائن فوراً.
class DeliverySettingsScreen extends StatefulWidget {
  const DeliverySettingsScreen({super.key});
  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> {
  final _free = TextEditingController();
  final _price = TextEditingController();
  final _max = TextEditingController();
  final _mapController = MapController();

  bool _enabled = false;
  LatLng? _restaurantPoint;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<DeliveryService>().load();
      _fillFromSettings();
    });
  }

  void _fillFromSettings() {
    final s = context.read<DeliveryService>().settings;
    setState(() {
      _enabled = s.enabled;
      _free.text = s.freeDistanceKm.toString();
      _price.text = s.pricePerKm.toString();
      _max.text = s.maxDistanceKm.toString();
      _restaurantPoint = s.hasRestaurantLocation
          ? LatLng(s.restaurantLatitude!, s.restaurantLongitude!)
          : null;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _free.dispose();
    _price.dispose();
    _max.dispose();
    super.dispose();
  }

  double _num(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim()) ?? fallback;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<DeliveryService>();

    final updated = DeliverySettings(
      enabled: _enabled,
      restaurantLatitude: _restaurantPoint?.latitude,
      restaurantLongitude: _restaurantPoint?.longitude,
      freeDistanceKm: _num(_free, 1),
      pricePerKm: _num(_price, 0.5),
      maxDistanceKm: _num(_max, 10),
    );

    if (updated.enabled && !updated.hasRestaurantLocation) {
      messenger.showSnackBar(
          const SnackBar(content: Text('حدّد موقع المطعم على الخريطة قبل تفعيل التوصيل')));
      return;
    }

    try {
      await service.save(updated);
      messenger.showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات التوصيل')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeliveryService>();
    final user = context.watch<AuthService>().user;
    final canEdit = PermissionService.can(user, Permission.editDeliverySettings);

    if (service.loading && !_initialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعدادات التوصيل')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final center = _restaurantPoint ?? const LatLng(31.9539, 35.9106); // عمّان للعرض فقط

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات التوصيل')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              value: _enabled,
              onChanged: canEdit ? (v) => setState(() => _enabled = v) : null,
              activeColor: AppColors.gold,
              title: Text(_enabled ? 'التوصيل: 🟢 مفعّل' : 'التوصيل: 🔴 متوقف',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              subtitle: const Text('عند التعطيل لا يستطيع الزبائن اختيار التوصيل من الموقع',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(height: 14),

          const Text('  موقع المطعم',
              style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(canEdit ? 'اضغط على الخريطة لتحديد موقع المطعم' : 'عرض فقط — لا تملك صلاحية التعديل',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 230,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _restaurantPoint != null ? 15 : 12,
                  onTap: canEdit
                      ? (_, p) => setState(() => _restaurantPoint = p)
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.diyaralanbat.diyar_admin',
                  ),
                  if (_restaurantPoint != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _restaurantPoint!,
                        width: 40, height: 40,
                        child: const Text('🏪', style: TextStyle(fontSize: 28)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _readonlyField('Latitude',
                    _restaurantPoint?.latitude.toStringAsFixed(6) ?? '—'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _readonlyField('Longitude',
                    _restaurantPoint?.longitude.toStringAsFixed(6) ?? '—'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text('  رسوم التوصيل',
              style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _numberField('المسافة المجانية (كم)', _free, canEdit),
          const SizedBox(height: 10),
          _numberField('سعر الكيلومتر (د.أ)', _price, canEdit),
          const SizedBox(height: 10),
          _numberField('أقصى مسافة للتوصيل (كم)', _max, canEdit),

          const SizedBox(height: 10),
          const Text(
            'طريقة الحساب: المسافة الجوية. كل كيلومتر بعد المسافة المجانية يُقرَّب لأعلى.\n'
            'الحساب النهائي يتم في الخادم لكل طلب.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.7),
          ),

          if (canEdit) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: service.saving ? null : _save,
              icon: service.saving
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('حفظ إعدادات التوصيل'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberField(String label, TextEditingController c, bool enabled) => TextField(
        controller: c,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label,
            labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );

  Widget _readonlyField(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(color: AppColors.textMain, fontSize: 13)),
          ],
        ),
      );
}
