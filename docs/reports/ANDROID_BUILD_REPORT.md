# ANDROID BUILD REPORT — v0.1

الحالة: **BLOCKED** — لم يُصدَّر أي APK.

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

## لماذا لا يوجد APK

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
