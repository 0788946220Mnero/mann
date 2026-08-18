# ديار الأنباط — تطبيق الإدارة

تطبيق Flutter مستقل لإدارة طلبات مطاعم ديار الأنباط، يتصل بنفس الـ Backend الحالي.
**لا يستبدل لوحة التحكم القديمة ولا يعدّل الخادم.**

## المُنجز

**المرحلة الأولى:** الهيكل والمعمارية · التنقّل · تسجيل الدخول · الصفحة الرئيسية ·
شاشة الطلبات · تفاصيل الطلب وإجراءاته · الصلاحيات · الإشعارات المحلية والصوت ·
حالة المطعم · الإعدادات

**المرحلة الثانية:** لوحة الإحصائيات (مبيعات اليوم والشهر، متوسط قيمة الطلب،
أكثر المنتجات طلباً) · سجل الطلبات السابقة مع البحث والتصفية بالتاريخ ·
الحساب الشخصي وتغيير كلمة المرور

**المتبقّي (يحتاج مسارات جديدة في الخادم):** الدردشة الداخلية · إدارة المستخدمين ·
سجل العمليات · إشعارات الخلفية (FCM) · WebSocket. التفاصيل في `REQUIRED_APIS.md`.

## التشغيل

```bash
flutter pub get
flutter run
```

### ربط خادم مختلف (رواء مثلاً)
```bash
flutter run --dart-define=API_BASE_URL=https://res-production-4ce8.up.railway.app
```

### تفعيل الوقت الحقيقي عند توفّره
```bash
flutter run --dart-define=WS_URL=wss://your-server/ws
```

## البناء

```bash
flutter build apk --release            # Android APK
flutter build appbundle --release      # Android AAB (متجر Play)
flutter build ios --release            # iOS (يتطلب macOS)
```

## البنية

```
lib/
  core/        api · models · services · storage · websocket · theme · widgets
  features/    auth · dashboard · orders · chat · notifications ·
               users · permissions · restaurant · content · settings
```

## ملاحظات مهمة

**صوت التنبيه:** ضع ملفاً باسم `new_order.mp3` في `assets/sounds/`. التطبيق لا يتعطّل إن غاب.

**الوقت الحقيقي:** يعمل حالياً بالاستطلاع كل ٨ ثوانٍ. راجع `REQUIRED_APIS.md` لتفعيل WebSocket.

**الصلاحيات:** مطابقة لما يسمح به الخادم فعلياً — التطبيق يخفي ما لا يملكه المستخدم، والخادم يبقى خط الدفاع الأخير.
