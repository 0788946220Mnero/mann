import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/order.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/delivery_service.dart';
import '../../core/theme/app_theme.dart';
import '../permissions/permission_service.dart';

/// بطاقة معلومات التوصيل داخل تفاصيل الطلب:
/// خريطة (المطعم + العميل) + المسافة والرسوم + زر فتح الموقع خارجياً.
/// كل الأرقام تأتي محسوبة من الخادم — لا يُعاد حسابها هنا (البند ١٣).
class DeliveryInfoCard extends StatelessWidget {
  const DeliveryInfoCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    if (!order.isDelivery) return const SizedBox.shrink();

    final user = context.watch<AuthService>().user;
    final canSeeLocation = PermissionService.can(user, Permission.viewCustomerLocation);
    final delivery = context.watch<DeliveryService>().settings;

    final custPoint = order.hasLocation
        ? LatLng(order.customerLatitude!, order.customerLongitude!)
        : null;
    final restPoint = delivery.hasRestaurantLocation
        ? LatLng(delivery.restaurantLatitude!, delivery.restaurantLongitude!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.delivery_dining, size: 18, color: AppColors.gold),
              SizedBox(width: 7),
              Text('معلومات التوصيل',
                  style: TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14.5)),
            ]),
            const SizedBox(height: 10),

            _row('نوع الطلب', '🚗 توصيل'),
            if (order.address.isNotEmpty) _row('العنوان', order.address),
            if (order.deliveryDistance != null)
              _row('المسافة من المطعم', '${order.deliveryDistance} كم'),
            _row('رسوم التوصيل',
                order.deliveryFee == 0 ? 'مجاني' : '${order.deliveryFee.toStringAsFixed(2)} د.أ'),
            _row('الإجمالي النهائي', '${order.total.toStringAsFixed(2)} د.أ'),

            if (canSeeLocation && order.hasLocation) ...[
              _row('Latitude', order.customerLatitude!.toStringAsFixed(6)),
              _row('Longitude', order.customerLongitude!.toStringAsFixed(6)),
              const SizedBox(height: 12),

              // الخريطة: علامة المطعم وعلامة العميل وخط بينهما
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: custPoint!,
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.diyaralanbat.diyar_admin',
                      ),
                      if (restPoint != null)
                        PolylineLayer(polylines: [
                          Polyline(
                            points: [restPoint, custPoint],
                            color: AppColors.gold.withOpacity(.8),
                            strokeWidth: 3,
                          ),
                        ]),
                      MarkerLayer(markers: [
                        if (restPoint != null)
                          Marker(
                            point: restPoint,
                            width: 40, height: 40,
                            child: const Text('🏪', style: TextStyle(fontSize: 26)),
                          ),
                        Marker(
                          point: custPoint,
                          width: 40, height: 40,
                          child: const Text('📍', style: TextStyle(fontSize: 28)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('فتح موقع العميل'),
                  onPressed: () => _openExternalMap(context, custPoint),
                ),
              ),
            ] else if (!canSeeLocation) ...[
              const SizedBox(height: 8),
              const Text('لا تملك صلاحية عرض موقع العميل',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ] else ...[
              const SizedBox(height: 8),
              const Text('لم يحدّد الزبون موقعه على الخريطة لهذا الطلب',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  /// فتح الموقع في تطبيق الخرائط على الهاتف باستخدام الإحداثيات (لا العنوان النصي).
  Future<void> _openExternalMap(BuildContext context, LatLng p) async {
    final messenger = ScaffoldMessenger.of(context);
    final geo = Uri.parse('geo:${p.latitude},${p.longitude}?q=${p.latitude},${p.longitude}');
    final web = Uri.parse('https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');

    try {
      if (await canLaunchUrl(geo)) {
        await launchUrl(geo, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط')));
    }
  }

  static Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 13.5))),
          ],
        ),
      );
}
