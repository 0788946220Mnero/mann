# إصلاح خطأ "Did not find xcodeproj" — دليل التنفيذ

## التشخيص

مجلد `ios/` **غير موجود إطلاقاً** في المشروع (وكذلك `android/`).
المشروع يحتوي `lib/` و`pubspec.yaml` فقط — ولهذا فشل Codemagic.

هذا طبيعي: ملفات المنصات تُولَّد بأمر Flutter رسمي، ولا تُكتب يدوياً
لأن `Runner.xcodeproj/project.pbxproj` ملف Xcode معقّد بمعرّفات مترابطة.

## الحل — خطوة واحدة على جهازك

```bash
cd diyar_admin
./setup_platforms.sh
```

أو يدوياً:

```bash
flutter create --platforms=android,ios --org com.diyaralanbat --project-name diyar_admin .
flutter pub get
```

**مهم:** هذا الأمر **لا يمسّ** مجلد `lib/` ولا `pubspec.yaml` ولا أي كود كتبته.
يضيف فقط مجلدَي `ios/` و`android/` الناقصين.

## ثم ادفع للمستودع

```bash
git add ios android pubspec.lock
git commit -m "إضافة ملفات منصتي iOS و Android"
git push
```

ثم أعد Build على Codemagic — سينجح.

## ما يجب أن تراه بعد التوليد

```
ios/
  Runner.xcodeproj/project.pbxproj   ← الملف الذي يبحث عنه Codemagic
  Runner.xcworkspace/
  Runner/
    Info.plist
    AppDelegate.swift
    Assets.xcassets/
  Podfile
  Flutter/
android/
  app/build.gradle
  gradle/
```

## تعديلات iOS المطلوبة بعد التوليد

### ١) أذونات في `ios/Runner/Info.plist`

أضف قبل `</dict>` الأخير:

```xml
<!-- إشعارات الطلبات الجديدة -->
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>

<!-- دعم العربية -->
<key>CFBundleLocalizations</key>
<array>
  <string>ar</string>
  <string>en</string>
</array>
```

### ٢) الحد الأدنى لإصدار iOS في `ios/Podfile`

غيّر السطر الأول (أزل التعليق إن كان معلّقاً):

```ruby
platform :ios, '13.0'
```

مطلوب لـ `flutter_secure_storage` و`flutter_local_notifications`.

## ملاحظة على `.gitignore`

صُحّح ليضمن رفع ملفات iOS الضرورية، مع استثناء المُولَّد محلياً فقط
(`ios/Pods/`, `ios/.symlinks/`, `ios/Flutter/ephemeral/`).
**لا تضف `ios/` أو `android/` إلى `.gitignore`** وإلا تكرّر الخطأ.
