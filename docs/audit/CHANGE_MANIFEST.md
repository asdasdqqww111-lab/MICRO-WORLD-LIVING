# CHANGE MANIFEST — جلسة إعادة البناء (2026-11-12)

كل مسار هنا جديد أو معدّل في هذه الجلسة. لم يُحذف أي ملف ولا أي نظام عامل.
Commit الأساس قبل الجلسة: `593ccf2` + عمل المراحل 0–7 السابق.

| # | الملف | النوع | السبب |
|---|---|---|---|
| 1 | `scripts/world/terrain.gd` | **جديد** | تضاريس إجرائية حتمية (ArrayMesh + trimesh collider) بدل المستوى المسطّح؛ القرية والغابة الغربية مسطّحتان تمامًا حتى تبقى كل المواضع والمصادمات المنسوخة صحيحة |
| 2 | `scripts/world/cloud_layer.gd` | **جديد** | طبقة سحب رخيصة (12 quad + نسيج ضجيج مولَّد في الذاكرة) بدل skybox ساكن |
| 3 | `scripts/world/world_root.gd` | معدّل | بناء التضاريس، سماء/إضاءة/ضباب محسّنة، قمر، سحب، `_optimize_static_props()` لخفض Draw Calls، تقليل مسافة الظل |
| 4 | `scripts/world/world_builder.gd` | معدّل | توسيط المجسمات أفقيًا (`_model_bounds`) لإصلاح محاور KayKit المنحازة (السياج)، تصغير البئر، إضاءة داخلية/مشاعل |
| 5 | `scripts/core/settings_manager.gd` | معدّل | أول تشغيل على الهاتف = Graphics Low تلقائيًا |
| 6 | `tests/screenshot_probe.gd` + `.tscn` | **جديد** | لقطات حقيقية من المحرك (9 مشاهد) + watchdog + سجل تشخيصي |
| 7 | `tests/perf_probe.gd` + `.tscn` | **جديد** | قياس Draw Calls/Triangles لكل منطقة + تحليل موارد المشهد + تفصيل أكبر المستهلكين |
| 8 | `.github/workflows/android.yml` | معدّل | خطوات قياس/لقطات حقيقية (Mesa GLES3)، سجلات تشخيص مرفوعة، تصدير APK + تحقق apksigner/aapt2 + نشر Release |
| 9 | `.github/workflows/probe.yml` | **جديد** | حلقة سريعة (بلا APK) للقياس واللقطات |
| 10 | `docs/audit/PROJECT_AUDIT.md` | **جديد** | تدقيق المشروع والقرارات التقنية المبنية عليه |
| 11 | `docs/audit/RECOVERY.md` | **جديد** | نسخة احتياطية + إجراء استعادة |
| 12 | `docs/audit/CHANGE_MANIFEST.md` | **جديد** | هذا الملف |
| 13 | `docs/reports/TEST_RUN_LOG.md`, `ANDROID_BUILD_REPORT.md`, `KNOWN_ISSUES.md`, `README.md` | معدّل | أرقام وروابط حقيقية (APK، 113 فحصًا، قياسات) |
| 14 | `docs/screenshots/*.png` | **جديد** | 9 لقطات مولّدة من المشروع نفسه على CI |
| 15 | `docs/reports/perf_probe_results.txt`, `ci_*.log` | **جديد** | أدلة قياس وتشخيص قابلة للتحقق |

## ما لم يُمَس
`scenes/`، صيغة الحفظ (schema v3) وواجهات `SaveManager`/`GameManager`، مسارات الموارد،
رسم المهام، الـ autoloads، إعداد التصدير (عدا تفعيل armeabi-v7a).
