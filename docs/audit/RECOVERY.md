# RECOVERY — كيف تستعيد المشروع من النسخة الاحتياطية

## النسخة الاحتياطية الحالية
| بند | قيمة |
|---|---|
| المسار | `/home/user/BACKUPS/micro-world-living-20261112-200118/` |
| الأرشيف | `project-full-20261112-200118.tar.gz` (22.1 MB، 1042 مدخلًا) |
| SHA-256 | `2642210f8174c0de3ffc1ff4b0a645e433e7e139b68ef78658a7e5476d17d7ef` |
| إعدادات منفصلة | `config/` (project.godot, export_presets.cfg, .gitignore, .github) |
| حالة Git الأصلية | `git/` (HEAD, log, status) |
| تحقق | استُخرج الأرشيف وفحص: `scripts/`, `assets/`, `docs/` سليمة ✅ |

> النسخة الاحتياطية **خارج مجلد المشروع**، ولا تُستبدل أبدًا. لإنشاء واحدة جديدة
> استخدم اسمًا زمنيًا جديدًا ولا تحذف القديمة.

## خطوات الاستعادة
```bash
# 1) تحقق من السلامة قبل أي شيء
sha256sum -c /home/user/BACKUPS/micro-world-living-20261112-200118/SHA256.txt

# 2) استعادة إلى مجلد جديد (لا فوق المشروع الحالي)
mkdir -p /tmp/restore && tar -xzf /home/user/BACKUPS/micro-world-living-20261112-200118/project-full-20261112-200118.tar.gz -C /tmp/restore
ls /tmp/restore            # README.md assets docs scripts ...

# 3) لو أردت إرجاع المشروع نفسه
#    (لا تستخدم git reset --hard على عمل غير محفوظ)
cp -a /home/user/MICRO-WORLD-LIVING /home/user/MICRO-WORLD-LIVING.broken-$(date +%s)
rsync -a --exclude .godot /tmp/restore/ /home/user/MICRO-WORLD-LIVING/

# 4) إعادة الاستيراد والتشغيل
godot --headless --path /home/user/MICRO-WORLD-LIVING --import
godot --headless --path /home/user/MICRO-WORLD-LIVING tests/test_runner.tscn
```

## استعادة الملفات المُعدّلة فقط
كل تغيير في هذا الفرع مقسّم إلى كوميتات صغيرة موصوفة؛ لاسترجاع ملف واحد:
```bash
git log --oneline -- <path>        # اعرف الكوميت السابق
git show <commit>:<path> > <path>  # أعِد نسخته السابقة (لا تحذف الحالي أولًا)
```

## ما لا يجب فعله
- `rm -rf` على المشروع أو النسخة الاحتياطية.
- `git reset --hard` / `git clean -fd` مع وجود تغييرات غير محفوظة.
- الكتابة فوق النسخة الاحتياطية الوحيدة.
