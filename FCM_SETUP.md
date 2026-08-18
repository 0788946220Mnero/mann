# إعداد إشعارات FCM — تطبيق إدارة ديار الأنباط

## ١) متغيّرات البيئة المطلوبة في Railway

أضف هذه الثلاثة **فقط** (لا ترسل قيمها في أي محادثة، ولا تضعها في Git):

```
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
```

تحصل عليها من: Firebase Console ← Project Settings ← Service Accounts ←
Generate new private key. يُنزَّل ملف JSON، خذ منه ثلاث قيم فقط:
`project_id` و`client_email` و`private_key`.

**مهم عند لصق `FIREBASE_PRIVATE_KEY`:** انسخ النص كاملاً بما فيه
`-----BEGIN PRIVATE KEY-----` و`-----END PRIVATE KEY-----`.
Railway يحفظ `\n` كنص، والخادم يحوّلها تلقائياً لأسطر حقيقية.

**بدون هذه المتغيّرات:** الخادم يعمل طبيعياً تماماً، ويُسجّل رسالة
"إشعارات FCM غير مفعّلة" — ولا يتعطّل أي شيء آخر.

## ٢) إعداد تطبيق Flutter

يحتاج التطبيق حزمة `firebase_messaging` للحصول على رمز الجهاز:

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

ثم من Firebase Console:
- **Android:** نزّل `google-services.json` ← ضعه في `android/app/`
- **iOS:** نزّل `GoogleService-Info.plist` ← أضفه في Xcode داخل `Runner/`

ثم في `main.dart` بعد تسجيل الدخول:

```dart
final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await context.read<DeviceService>().register(
    token,
    platform: Platform.isIOS ? 'ios' : 'android',
  );
}
```

`DeviceService` جاهزة بالكامل وتنتظر الرمز فقط.

## ٣) اختبار FCM

1. سجّل الدخول من التطبيق (يُسجَّل الجهاز تلقائياً بعد إضافة الخطوة أعلاه).
2. تحقّق: `GET /api/devices/my` يُرجع جهازك.
3. أنشئ طلباً من موقع الزبائن.
4. راجع سجلات Railway — يجب أن ترى: `🔔 إشعار الطلب #XXXX: أُرسل 1 / فشل 0`
5. أغلق التطبيق تماماً وأنشئ طلباً آخر — يجب أن يصلك الإشعار.

## ٤) اختبار WebSocket

1. افتح التطبيق وسجّل الدخول.
2. راجع سجلات Railway عند الإقلاع: `🔌 خدمة الوقت الحقيقي (WebSocket) جاهزة على /ws`
3. أنشئ طلباً من الموقع — يجب أن يظهر في التطبيق **فوراً** (بلا انتظار ٨ ثوانٍ).
4. غيّر حالة الطلب من لوحة التحكم القديمة — يتحدّث التطبيق فوراً.
5. **اختبار الاحتياطي:** أوقف الإنترنت لحظياً ثم أعده — يعود الاستطلاع
   تلقائياً ثم يُعاد اتصال WebSocket خلال ٥ ثوانٍ.

## ٥) الصلاحيات في WebSocket

الاتصال يتطلّب JWT صالحاً في الرابط (`/ws?token=...`).
الرمز غير الصالح يُغلق الاتصال فوراً برمز `4002`.
وأحداث الطلبات تُرسَل فقط لأصحاب أدوار: admin · manager · cashier · employee.
