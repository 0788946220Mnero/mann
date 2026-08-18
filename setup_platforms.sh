#!/usr/bin/env bash
# توليد مجلدات المنصات (ios / android) بالطريقة الرسمية من Flutter.
# شغّله مرة واحدة داخل مجلد المشروع، ثم ادفع النتيجة إلى Git.
set -e

echo "▸ التحقق من Flutter..."
flutter --version

echo "▸ توليد ملفات المنصات (لن يمسّ lib/ ولا pubspec.yaml)..."
flutter create --platforms=android,ios --org com.diyaralanbat --project-name diyar_admin .

echo "▸ حل الاعتماديات..."
flutter pub get

echo "▸ التحقق من ملفات iOS الأساسية..."
for f in ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist ios/Podfile; do
  if [ -f "$f" ]; then echo "  ✓ $f"; else echo "  ✗ ناقص: $f"; fi
done

echo ""
echo "✅ تم. الخطوات التالية:"
echo "   git add ios android pubspec.lock"
echo "   git commit -m \"إضافة ملفات منصتي iOS و Android\""
echo "   git push"
