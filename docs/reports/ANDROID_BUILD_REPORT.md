# ANDROID BUILD REPORT — v0.1

الحالة: **APK مبني وموقَّع ومتحقَّق منه آليًا** ✅ · **لم يُثبَّت على هاتف بعد** ⏳

> **رابط التنزيل المباشر**
> `https://github.com/asdasdqqww111-lab/MICRO-WORLD-LIVING/releases/download/v0.1-debug/micro_world_living.apk`
> صفحة الإصدار: `https://github.com/asdasdqqww111-lab/MICRO-WORLD-LIVING/releases/tag/v0.1-debug`

## ما الذي تغيّر (2026-11-12)

بيئة الصندوق لا تحتوي JDK ولا Android SDK ولا قوالب تصدير، فبُني الـ APK على
**GitHub Actions** (`ubuntu-latest` فيه OpenJDK 17 + Android SDK كاملًا) عبر
`.github/workflows/android.yml`. الـ workflow يعمل مع كل دفعة على الفرع:

1. تنزيل Godot 4.3-stable + `export_templates.tpz` (الشبكة متاحة هناك).
2. كتابة `editor_settings-4.3.tres` بمساري `android_sdk_path` و `java_sdk_path`.
3. `--import` ثم **تشغيل 113 فحصًا headless** (يفشل البناء إن فشل أي فحص).
4. توليد debug keystore بـ `keytool` وحقنه في `export_presets.cfg`.
5. `--export-debug "Android"` ⇒ `build/android/micro_world_living.apk`.
6. **تحقق إجباري**: `apksigner verify` + `aapt2 dump badging`.
7. نشر الـ APK في GitHub Release + رفع Artifact.

## نتيجة البناء الحقيقية

| بند | القيمة |
|---|---|
| الحجم | 58,386,088 بايت (≈55.7 ميبي) |
| SHA-256 | `8338b095e1fc48faa3e25699f76bd1ee73d71a434b2c484a287c65148566d3de` |
| الحزمة | `com.microworldliving.game` — نسخة 0.1 (versionCode 1) |
| minSdk / targetSdk / compileSdk | 21 (Android 5.0) / 34 / 34 |
| المعماريات | `arm64-v8a` + `armeabi-v7a` (`libgodot_android.so`, `libc++_shared.so`) |
| التوقيع | v1 JAR ✅ · v2 ✅ · v3 ✅ — شهادة `CN=Android Debug, O=Android, C=US` |
| فحوص headless داخل CI | 113 نجحت / 0 فشلت |
| زمن الـ workflow | ~60 ثانية |

```
=== apksigner verify ===
Verifies
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1

=== aapt2 dump badging ===
package: name='com.microworldliving.game' versionCode='1' versionName='0.1'
minSdkVersion:'21'  targetSdkVersion:'34'
application-label:'Micro World: Living'

=== native libs + key entries ===
classes.dex … classes4.dex
lib/arm64-v8a/libc++_shared.so
lib/arm64-v8a/libgodot_android.so
lib/armeabi-v7a/libc++_shared.so …
```

## ما زال غير مُتحقَّق

- **لم يُشغَّل على هاتف** — لا جهاز في البيئة. "APK مبني وموقَّع" ≠ "APK يعمل".
- الأداء (FPS / draw calls) غير مقيس. عند التشغيل: F3 لطبقة الأداء ⇒ يُكتب
  `user://perf_log.txt` كل 5 ثوانٍ (`adb pull /sdcard/Android/data/com.microworldliving.game/files/perf_log.txt`).
- توقيع **debug** فقط. توقيع الإصدار يتطلب keystore الاستوديو الخاص (`keytool -genkeypair`
  ثم تعبئة `keystore/release*` في `export_presets.cfg`) — لا نُنشئ مفتاح نشر مزيّفًا.
- محاكيات x86_64 غير مدعومة في هذا الإعداد (تتطلب بناء Gradle).

## ما هو جاهز فعلًا

| عنصر | الحالة | الملف |
|---|---|---|
| Android export preset (Compatibility, arm64-v8a) | جاهز | `export_presets.cfg` |
| Rendering method = `gl_compatibility` (وهو الوحيد المسموح) | مضبوط | `project.godot` |
| Landscape orientation (sensor landscape) | مضبوط | `project.godot` |
| `import_etc2_astc=true` لتضغيط textures على Android | مضبوط | `project.godot` |
| Immersive mode + دعم كل أحجام الشاشات | مضبوط | `export_presets.cfg` |
| معالجة زر الرجوع (`NOTIFICATION_WM_GO_BACK_REQUEST`) | منفّذ | `scripts/core/game.gd` |
| واجهة لمس كاملة | منفّذ | `scripts/ui/touch_controls.gd` |

## لماذا فشل التصدير داخل الصندوق (سجل تاريخي)

1. **لا Android SDK / build-tools / platform-tools** في البيئة.
2. **لا JDK** (Godot 4 Android export يتطلب OpenJDK 17).
3. **لا export templates مثبتة**: تحميل `Godot_v4.3-stable_export_templates.tpz`
   يتطلب الوصول إلى `objects.githubusercontent.com` وهو محجوب (كل تنزيلات
   GitHub Releases تُعاد توجيهها إلى ذلك المضيف). جلب الشيفرة عبر git يعمل،
   لكن ملفات الإصدارات لا.
4. `sdkmanager` و Gradle يحتاجان `dl.google.com` و `services.gradle.org` — محجوبان.

## ما يجب على جهاز حقيقي (5 خطوات)

```bash
# 1) تثبيت export templates المطابقة
#    Editor > Manage Export Templates > Install from file
#    (Godot_v4.3-stable_export_templates.tpz)

# 2) إعداد المسارات
export ANDROID_HOME=$HOME/Android/Sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# 3) استيراد الأصول (مرة واحدة)
godot --headless --path . --import

# 4) تصدير APK للتجريب (debug، موقّع بمفتاح debug تلقائيًا)
mkdir -p build/android
godot --headless --path . --export-debug "Android" build/android/micro_world_living.apk

# 5) تثبيت واختبار
adb install -r build/android/micro_world_living.apk
adb shell am start -n com.microworldliving.game/com.godot.game.GodotApp
adb logcat | grep -i godot
```

للإصدار الموقّع (release) يلزم keystore:

```bash
keytool -genkey -v -keystore release.keystore -alias microworld \
        -keyalg RSA -keysize 2048 -validity 10000
# ثم في Godot: Project > Export > Android > Keystore > (المسار + alias + كلمات السر)
godot --headless --path . --export-release "Android" build/android/micro_world_living-release.apk
```

## ما سيُقاس على الجهاز (غير مقيس هنا)

| مقياس | المستهدف | الطريقة |
|---|---|---|
| FPS | ≥ 30 مستقر | `F3` overlay أو `Engine.get_frames_per_second()` |
| Draw calls | < 200 (حد 300) | `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` |
| Triangles | < 150,000 | `RENDER_TOTAL_PRIMITIVES_IN_FRAME / 3` |
| Texture memory | < 200 MB | Monitors > Video Mem |
| حجم APK | — | `ls -lh build/android` |

## الخلاصة

المشروع **قابل للتصدير** بلا تعديل كود، لكن التصدير نفسه **لم يحدث** ولم يُثبَّت
APK على أي جهاز. لذلك لا توجد أي عبارة `VERIFIED` في هذا المستودع.
