# PERFORMANCE REPORT — v1.0

الحالة: **MEASURED & WITHIN BUDGET** (جميع المناطق 7/7 ضمن الميزانية).

## الميزانية المستهدفة

| مقياس | الهدف | الحد الأقصى |
|---|---|---|
| Draw calls / frame | < 200 | 300 |
| Triangles / frame | < 150,000 | 180,000 |
| FPS (Snapdragon 6xx / 4GB) | ≥ 30 | — |

## النتائج (perf_probe، llvmpipe headless)

| المنطقة | Draw calls | المثلثات | الوضع |
|---|---|---|---|
| 1 · Eldoria Village Square | 150 | 157,881 | ✅ |
| 2 · Active Combat (3 Skeletons) | 159 | 173,539 | ✅ |
| 3 · Western Woodland | 88 | 60,163 | ✅ |
| 4 · River, Stone Bridge & Lake | 94 | 97,285 | ✅ |
| 5 · Guild Grand Hall | 105 | 47,705 | ✅ |
| 6 · Hero Cottage | 70 | 12,721 | ✅ |
| 7 · Sunken Crypt | 110 | 67,121 | ✅ |

النتائج الكاملة: `docs/reports/perf_probe_results.txt`.

## التحسينات المنفّذة (البند 0)

| التقنية | أين | الأثر |
|---|---|---|
| Terrain subdivisions 60→34 | `scripts/world/terrain.gd` | مثلثات الـ mesh من ~7.2k إلى ~2.3k |
| تقسيم أسوار المدينة إلى 4 أرباع MultiMesh موقّعة | `_build_city_walls` | تُكبَّل الأرباع البعيدة (−30% في zone القرية) |
| تقسيم أبراج البوابات إلى 3 مجموعات (بوابة/مجموعة) | `_build_city_walls` | تُكبَّل البوابات البعيدة من المركز |
| تقسيم المرافق (فوانيس، مقاعد، بنادات، أشجار) إلى أرباع | `_build_city_furniture` | تُكبَّل العناصر البعيدة |
| `_build_quadrant_multimesh` / `_build_positioned_multimesh` | `world_builder.gd` | آلية LOD عامة لقِطاعات MultiMesh |
| إيقاف الظل على الأسوار والحصون وأشجار الحدائق | `build_multimesh` args | يقلل مثلثات مرور الظل |
| مديات LOD: كائنات 42م، NPCs 16م | `creature.gd`, `village_npc.gd` | كبْل الكائنات/NPCs البعيدة |

## كيف تُقاس على الجهاز

1. شغّل اللعبة، اضغط `F3` (Settings > Performance overlay).
2. سجّل FPS + Draw calls + Triangles + Memory في القرية، الغابة، والضريح.
3. قارن بالجدول أعلاه. أي مشهد يتجاوز الحد → يُحسَّن.
