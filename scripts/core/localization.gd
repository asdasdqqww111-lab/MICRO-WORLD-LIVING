class_name Localization
extends RefCounted
## Bilingual UI localization (English + Arabic RTL) with bundled SIL OFL 1.1
## NotoSans + NotoSansArabic font support.

const LANG_EN := "en"
const LANG_AR := "ar"

const STRINGS := {
	"game_title": {"en": "MICRO WORLD: LIVING", "ar": "العالم المصغّر: الحياة"},
	"game_subtitle": {"en": "CHRONICLES OF ELDORIA", "ar": "سجلات إلدوريا"},
	"new_game": {"en": "New Journey", "ar": "رحلة جديدة"},
	"continue": {"en": "Continue", "ar": "متابعة"},
	"load_game": {"en": "Save Slots", "ar": "ملفات الحفظ"},
	"settings": {"en": "Settings", "ar": "الإعدادات"},
	"quit": {"en": "Quit", "ar": "خروج"},
	"language": {"en": "Language", "ar": "اللغة"},
	"lang_name": {"en": "English", "ar": "العربية"},
	"no_save": {"en": "Begin your adventure in Eldoria", "ar": "ابدأ مغامرتك في ربوع إلدوريا"},
	"hud_level": {"en": "Lv.", "ar": "مستوى"},
	"hud_gold": {"en": "Gold", "ar": "ذهب"},
	"hud_rank": {"en": "Guild Rank", "ar": "رتبة النقابة"},
	"hud_day": {"en": "Day", "ar": "اليوم"},
	"screen_inventory": {"en": "Inventory & Equipment", "ar": "الحقيبة والتجهيز"},
	"screen_character": {"en": "Hero Attributes", "ar": "خصائص البطل"},
	"screen_skills": {"en": "Skill Tree", "ar": "شجرة المهارات"},
	"screen_journal": {"en": "Quest Journal", "ar": "سجل المهام"},
	"screen_guild": {"en": "Adventurers Guild", "ar": "نقابة المغامرين"},
	"screen_crafting": {"en": "Forge & Crafting", "ar": "الحدادة والتصنيع"},
	"screen_map": {"en": "Map of Eldoria", "ar": "خريطة إلدوريا"},
	"screen_shop": {"en": "Merchant", "ar": "المتجر"},
	"screen_pause": {"en": "Paused", "ar": "إيقاف مؤقت"},
	"screen_saves": {"en": "Save & Load", "ar": "الحفظ والتحميل"},
	"btn_close": {"en": "Close", "ar": "إغلاق"},
	"btn_resume": {"en": "Resume", "ar": "استئناف"},
	"btn_save": {"en": "Save Game", "ar": "حفظ اللعبة"},
	"btn_load": {"en": "Load Game", "ar": "تحميل اللعبة"},
	"btn_main_menu": {"en": "Main Menu", "ar": "القائمة الرئيسية"},
	"btn_register_guild": {"en": "Register as Adventurer", "ar": "التسجيل كمغامر"},
	"btn_reset_skills": {"en": "Reset Skills", "ar": "إعادة تعيين المهارات"},
	"btn_confirm_reset": {"en": "Confirm Reset (50 Gold)", "ar": "تأكيد الإعادة (50 ذهب)"},
	"btn_craft": {"en": "Craft", "ar": "تصنيع"},
	"weather_clear": {"en": "Clear Skies", "ar": "سماء صافية"},
	"weather_partly_cloudy": {"en": "Partly Cloudy", "ar": "غائم جزئياً"},
	"weather_overcast": {"en": "Overcast", "ar": "غائم كلياً"},
	"weather_rain": {"en": "Light Rain", "ar": "مطر خفيف"},
	"weather_heavy_rain": {"en": "Heavy Rain", "ar": "مطر غزير"},
	"weather_fog": {"en": "Misty Fog", "ar": "ضباب كثيف"},
	"weather_storm": {"en": "Thunderstorm", "ar": "عاصفة رعدية"},
}

static var _font_cached: Font = null
static var _font_bold_cached: Font = null

static func current_lang() -> String:
	if Engine.has_singleton("SettingsManager"):
		pass
	return SettingsManager.language if SettingsManager != null else LANG_EN

static func is_rtl() -> bool:
	return current_lang() == LANG_AR

static func t(key: String, fallback: String = "") -> String:
	var lang := current_lang()
	if STRINGS.has(key):
		var entry: Dictionary = STRINGS[key]
		if entry.has(lang):
			return String(entry[lang])
		if entry.has(LANG_EN):
			return String(entry[LANG_EN])
	return fallback if not fallback.is_empty() else key

static func apply_direction(control: Control) -> void:
	if control == null:
		return
	control.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_rtl() else Control.LAYOUT_DIRECTION_LTR

static func primary_font() -> Font:
	if _font_cached != null:
		return _font_cached
	var latin_path := "res://assets/ui/fonts/NotoSans-Medium.ttf"
	var arabic_path := "res://assets/ui/fonts/NotoSansArabic-Medium.ttf"
	if ResourceLoader.exists(latin_path):
		var base := ResourceLoader.load(latin_path) as FontFile
		if base != null:
			var fv := FontVariation.new()
			fv.base_font = base
			if ResourceLoader.exists(arabic_path):
				var ar := ResourceLoader.load(arabic_path) as FontFile
				if ar != null:
					fv.fallbacks = [ar]
			_font_cached = fv
			return _font_cached
	return ThemeDB.fallback_font

static func bold_font() -> Font:
	if _font_bold_cached != null:
		return _font_bold_cached
	var latin_bold := "res://assets/ui/fonts/NotoSans-Bold.ttf"
	var arabic_path := "res://assets/ui/fonts/NotoSansArabic-Medium.ttf"
	if ResourceLoader.exists(latin_bold):
		var base := ResourceLoader.load(latin_bold) as FontFile
		if base != null:
			var fv := FontVariation.new()
			fv.base_font = base
			if ResourceLoader.exists(arabic_path):
				var ar := ResourceLoader.load(arabic_path) as FontFile
				if ar != null:
					fv.fallbacks = [ar]
			_font_bold_cached = fv
			return _font_bold_cached
	return primary_font()
