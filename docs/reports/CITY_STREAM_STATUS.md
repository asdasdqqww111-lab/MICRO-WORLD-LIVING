# CITY STREAMING — تقرير الحالة (2026-11-13)

**الفرع:** `arena/city-stream` · **المحرك المستهدف:** Godot 4.3 (`gl_compatibility` / mobile)

## ما أُنجز في هذه الدفعة

| # | الملف | النوع | الحالة |
|---|---|---|---|
| 1 | `scripts/world/city_chunks.gd` | جديد | ✅ مُلتزم (`c559633`) |
| 2 | `tests/city_stream_probe.gd` | جديد | ✅ مُلتزم (`849377d`) |
| 3 | `scripts/world/city_player_tracker.gd` | جديد | ✅ مُلتزم (`beb6813`) |
| 4 | `.github/workflows/city.yml` | CI (مقترح) | ❌ فشل الالتزام 3 مرات (عطل موصّل) — المحتوى جاهز |

## مواصفات النواة المنفَّذة

- شبكة قطع **40×40 م**؛ كل حي يملك **كتلة 2×2 قطع صريحة** (جدول `DISTRICT_BLOCKS`) —
  6 أحياء: سكني، سوق، قصر ملكي، تل المعبد، مرافئ، حدائق الساكورا. حدود مدينة 240×240 م.
- **بثّ متدفّق:** تحميل ضمن قطعتين (80 م) من اللاعب، إفراغ خلف 3 قطع (120 م)،
  تحديث عبر `CityStreamPlayerTracker` كل 0.25 ثانية (لا تخصيص ذاكرة لكل إطار).
- **حتمية:** بذرة RNG لكل قطعة `(cx*73856093) ^ (cz*19349663)` — نفس القطعة = نفس المدينة.
- **ميزانية موبايل:** ≤ 2 MultiMesh لكل قطعة، StaticBody3D لكل مبنى،
  `BoxOccluder3D` لكل مبنى، شكل تصادم مشترك للأعمدة.
- **شريط بناء آمن من الطرق:** كل AABB مبنى يبقى داخل `|coord| + نصف البعد ≤ 12`
  (طرق 8 م على حدود القطع) — تُفحص آليًا.
- **زقاقات سكنية:** مبنيا القطعة على قطري ثابت + اهتزاز محدود ⇒ فاصل ≥ 12 م — تُفحص آليًا.

## حاكم الاختبارات (city_stream_probe.gd — 8 فحوص)

1. جدول الأحياء: 6 كتل غير متداخلة تغطي القطع 2..7، والخارج = مرج (-1).
2. حلقة التحميل أثناء مشي شبكي متعاقب (لا تفريغ زائد، ضمن ميزانية ≤ 25 قطعة).
3. التفريغ: قفزة بعيدة تُخلّي كل القطع القديمة (لا بقايا stale).
4. نافذة مركز المدينة تمتد ≥ 3 أحياء.
5. كل مباني كل الأحياء داخل شريط الطرق الآمن (أقصى تجاوز يُطبع).
6. فاصل الزقاقات السكنية ≥ 12 م (أدنى فاصل يُطبع).
7. حتمية: دفقان مستقلان ينتجان تخطيط محتوى متطابقًا تمامًا.
8. إشارة `chunk_loaded` تُطلق أثناء البثّ.

**أمر التشغيل:**
```bash
godot --headless --path . --script res://tests/city_stream_probe.gd
```

## حالة التحقق الفعلي

- CI الفرعي (`Android APK` + `Perf + Visual Probe`) يعمل على `beb6813` وينفّذ
  الاستيراد + **حزمة القبول الكاملة (190 فحصًا)** كحاجز قبل أي خطوة لاحقة.
  ⚠️ عند إعداد هذا التقرير: التشغيلان **لا يزالان قيد التنفيذ** — النتيجة
  الفعلية تُقرأ من صفحة Actions، ولا يُدّعى نجاح قبل ظهوره.

## الخطوة التالية المقترحة (بعد خضّرة CI)

1. دمج `CityChunkStream` في `WorldRoot._ready()` + تثبيت المتتبّع + ربط إشارة `zone_changed`.
2. **سدّ فجوة كاميرا 80–120 م** (زيادة `far` إلى 130 م + ضباب لوني مطابق للأفق).
3. `city.yml` (المحتوى جاهز في هذا التقرير أدناه) للحاكم المزدوج على كل دفعة.
4. تحويل بقايا `WorldBuilder` الثقيلة إلى قطع (دمج تدريجي بلا كسر الاختبارات الـ 190).

## محتوى CI المقترح (جاهز للّصق في `.github/workflows/city.yml`)

```yaml
name: City Pipeline

on:
  push:
    branches: ["arena/city-stream", "main"]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  city-tests:
    name: City streaming + full acceptance
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4

      - name: Install Godot 4.3 stable
        run: |
          set -euo pipefail
          curl -fsSL -o /tmp/godot.zip \
            https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
          unzip -q /tmp/godot.zip -d /tmp/godot
          chmod +x /tmp/godot/Godot_v4.3-stable_linux.x86_64
          sudo mv /tmp/godot/Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot
          godot --version

      - name: Import project
        run: godot --headless --path . --import

      - name: City streaming probe
        run: timeout 120 godot --headless --path . --script res://tests/city_stream_probe.gd

      - name: Full acceptance suite (must keep 190/190)
        run: timeout 180 godot --headless --path . tests/test_runner.tscn

      - name: Report test counts
        if: always()
        run: |
          grep -E "checks (passed|failed):" docs/reports/headless_test_results.txt || true
```
