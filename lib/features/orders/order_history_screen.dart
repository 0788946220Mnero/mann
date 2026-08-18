import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/models/order.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_chip.dart';
import 'order_detail_screen.dart';

/// سجل الطلبات السابقة — يشمل الطلبات المؤرشفة بإغلاق الجرد.
/// يستخدم المسار الحالي GET /api/orders?includeClosed=true
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/orders', query: {
        'includeClosed': 'true',
        'limit': '200',
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
      });
      final list = (res['data'] as List?) ?? [];
      _orders = list.map((e) => Order.fromJson(Map<String, dynamic>.from(e))).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر تحميل السجل';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _filtered {
    if (_range == null) return _orders;
    return _orders.where((o) {
      final d = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      final from = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
      final to = DateTime(_range!.end.year, _range!.end.month, _range!.end.day);
      return !d.isBefore(from) && !d.isAfter(to);
    }).toList();
  }

  double get _total => _filtered.fold(0.0, (t, o) => t + o.total);

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات'),
        actions: [
          IconButton(
            tooltip: 'تصفية بالتاريخ',
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _range,
                builder: (c, child) => Theme(
                  data: Theme.of(c).copyWith(
                    colorScheme: Theme.of(c).colorScheme.copyWith(primary: AppColors.gold),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _range = picked);
            },
          ),
          if (_range != null)
            IconButton(
              tooltip: 'إلغاء التصفية',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _range = null),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'ابحث برقم الطلب أو الاسم أو الهاتف',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppColors.gold),
                  onPressed: _load,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text('${list.length} طلب',
                    style: const TextStyle(color: AppColors.textMain, fontSize: 13)),
                const Spacer(),
                Text('الإجمالي: ${_total.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(
                        color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${DateFormat('yyyy/MM/dd').format(_range!.start)} — ${DateFormat('yyyy/MM/dd').format(_range!.end)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.statusNew)))
                    : list.isEmpty
                        ? const Center(
                            child: Text('لا توجد طلبات في هذه الفترة',
                                style: TextStyle(color: AppColors.textMuted)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 24),
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final o = list[i];
                                return Card(
                                  child: ListTile(
                                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(orderId: o.id),
                                    )),
                                    title: Row(
                                      children: [
                                        Text('#${o.orderNumber}',
                                            style: const TextStyle(
                                                color: AppColors.gold,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(o.customerName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 13.5)),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        DateFormat('yyyy/MM/dd — hh:mm a', 'ar').format(o.createdAt),
                                        style: const TextStyle(
                                            color: AppColors.textMuted, fontSize: 11.5),
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        StatusChip(o.status),
                                        const SizedBox(height: 4),
                                        Text('${o.total.toStringAsFixed(2)} د.أ',
                                            style: const TextStyle(
                                                color: AppColors.textMain,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
