# الـ Endpoints المطلوبة من الـ Backend

## ١) موجودة حالياً ويستخدمها التطبيق فعلياً ✅

| الغرض | المسار |
|---|---|
| تسجيل الدخول | `POST /api/auth/login` |
| تجديد الرمز | `POST /api/auth/refresh` |
| تسجيل الخروج | `POST /api/auth/logout` |
| بيانات المستخدم | `GET /api/auth/me` |
| تغيير كلمة المرور | `POST /api/auth/change-password` |
| قائمة الطلبات | `GET /api/orders?status=&search=&limit=` |
| تفاصيل طلب | `GET /api/orders/:id` |
| قبول الطلب | `PUT /api/orders/:id/confirm` |
| تغيير الحالة | `PUT /api/orders/:id/status` |
| إحصائيات | `GET /api/orders/stats/dashboard` |
| حالة المطعم | `PATCH /api/settings/status` |
| الإعدادات | `GET /api/settings` |
| قائمة المستخدمين | `GET /api/users` ✨ جديد |
| إنشاء مستخدم | `POST /api/users` ✨ جديد |
| تعديل مستخدم | `PUT /api/users/:id` ✨ جديد |
| حذف مستخدم | `DELETE /api/users/:id` ✨ جديد |
| إعدادات التوصيل | `GET /api/settings/delivery-config` 🚗 |
| حفظ إعدادات التوصيل | `PUT /api/settings` (delivery) 🚗 |
| تسعيرة التوصيل | `POST /api/settings/delivery-quote` 🚗 |

## ٢) غير موجودة — مطلوبة للمراحل التالية ❌

### أ) الوقت الحقيقي (المرحلة الثانية)
```
WebSocket: wss://<الخادم>/ws?token=<accessToken>

أحداث يرسلها الخادم:
  { "type": "order:new",    "order": { ... } }
  { "type": "order:update", "order": { ... } }
```
**الوضع الحالي:** التطبيق يعمل بالاستطلاع (Polling) كل ٨ ثوانٍ تلقائياً.
عند إضافة WebSocket، اضبط `WS_URL` فقط وسيعمل دون تعديل أي شاشة.

### أ-٢) إحصائيات التوصيل — مطلوبة للبند ٨ ❌

المسار الحالي `GET /api/orders/stats/dashboard` **لا يوفّر** إحصائيات التوصيل.
لم تُخترع بيانات وهمية في التطبيق. المطلوب إضافته إلى نفس المسار:

```js
// داخل getDashboardStats في controllers/orderController.js
const deliveryStatsAgg = await Order.aggregate([
  { $match: { createdAt: { $gte: startOfToday } } },
  { $group: {
      _id: '$orderType',
      count: { $sum: 1 },
      feesTotal: { $sum: '$deliveryFee' },
      avgDistance: { $avg: '$deliveryDistance' },
  }},
]);
```

ثم إضافتها للرد:
```json
{
  "deliveryToday": { "count": 12, "feesTotal": 9.50, "avgDistanceKm": 3.4 },
  "pickupToday":   { "count": 5 }
}
```

بعد إضافتها، تُعرض تلقائياً في شاشة الإحصائيات بالتطبيق (يحتاج ربطاً بسيطاً).

### ب) Push Notifications (المرحلة الثانية)
```
POST /api/devices/register    { token, platform }   # تسجيل جهاز لـ FCM
DELETE /api/devices/:token
```
ويحتاج الخادم إرسال إشعار FCM عند إنشاء طلب جديد.
**الوضع الحالي:** إشعارات محلية داخل التطبيق + صوت تنبيه (تعمل والتطبيق مفتوح).

### ج) الدردشة الداخلية (المرحلة الثالثة)
```
GET    /api/chat/conversations
POST   /api/chat/conversations              { participants[], name?, isGroup }
GET    /api/chat/conversations/:id/messages?before=&limit=
POST   /api/chat/conversations/:id/messages { text, attachments[] }
PUT    /api/chat/messages/:id/read
GET    /api/users/admins                    # قائمة مستخدمي الإدارة
WebSocket: message:new | message:read | typing | presence
```

### هـ) سجل العمليات (المرحلة الرابعة)
```
GET  /api/audit-logs?from=&to=&user=
POST /api/audit-logs   (يُسجَّل تلقائياً من الخادم)
```

### و) سجل الطلبات القديمة
```
GET /api/orders?includeClosed=true&from=&to=
```
موجود جزئياً (`includeClosed`) — يحتاج فلترة بالتاريخ.
