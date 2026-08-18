import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/app_config.dart';

/// خدمة الوقت الحقيقي — متصلة بخادم ديار الأنباط عبر /ws
///
/// المصادقة: يُرسَل رمز الدخول في الرابط (?token=...) ويتحقّق منه الخادم.
/// الأحداث: order.created | order.updated | order.status_changed | order.cancelled
///
/// إن فشل الاتصال أو انقطع، يعود التطبيق تلقائياً للاستطلاع (Polling)
/// فلا تتوقف الطلبات إطلاقاً.
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _controller.stream;

  /// رابط WebSocket: يُشتق تلقائياً من عنوان الـ API إن لم يُضبط صراحةً.
  String get _resolvedUrl {
    if (AppConfig.wsUrl.isNotEmpty) return AppConfig.wsUrl;
    final base = AppConfig.apiBaseUrl;
    if (base.startsWith('https://')) return '${base.replaceFirst('https://', 'wss://')}/ws';
    if (base.startsWith('http://')) return '${base.replaceFirst('http://', 'ws://')}/ws';
    return '';
  }

  bool get isEnabled => _resolvedUrl.isNotEmpty;
  bool _connected = false;
  bool get isConnected => _connected;

  String? _token;

  void connect(String? accessToken) {
    if (!isEnabled) return;
    if (accessToken != null) _token = accessToken;
    disconnect();
    try {
      final uri = Uri.parse('$_resolvedUrl?token=${accessToken ?? ''}');
      _channel = WebSocketChannel.connect(uri);
      _connected = true;
      _sub = _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String);
            if (data is Map<String, dynamic>) _controller.add(data);
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> data) {
    if (_connected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _scheduleReconnect() {
    _connected = false;
    _reconnectTimer?.cancel();
    if (!isEnabled) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), () => connect(_token));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _connected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
