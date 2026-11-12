class_name Localization
extends RefCounted
## Bilingual UI localization (English + Arabic RTL) with bundled SIL OFL 1.1
## NotoSans + NotoSansArabic font support.

const LANG_EN := "en"
const LANG_AR := "ar"

const STRINGS := {
	"game_title": {"en": "MICRO WORLD: LIVING", "ar": "العالم المصغّر: الحياة"},
	"game_subtitle": {"en": "CHRONICLES OF ELDORIA", "ar": "سجلات إلدوريا"},
	"welcome_eldoria": {"en": "Welcome to Eldoria — speak with Elder Theron or visit the Adventurers Guild!", "ar": "مرحباً بك في إلدوريا — تحدّث مع الحكيم أو زر نقابة المغامرين!"},
	"new_game": {"en": "New Adventure", "ar": "مغامرة جديدة"},
	"continue": {"en": "Continue", "ar": "متابعة"},
	"continue_game": {"en": "Continue Adventure", "ar": "متابعة المغامرة"},
	"save_game": {"en": "Save Game", "ar": "حفظ اللعبة"},
	"load_game": {"en": "Load Game", "ar": "تحميل اللعبة"},
	"settings": {"en": "Settings", "ar": "الإعدادات"},
	"quit": {"en": "Quit", "ar": "خروج"},
	"quit_menu": {"en": "Save & Return to Main Menu", "ar": "حفظ والعودة للقائمة الرئيسية"},
	"close": {"en": "Close", "ar": "إغلاق"},
	"resume": {"en": "Resume Adventure", "ar": "استئناف المغامرة"},
	"paused": {"en": "Paused & Settings", "ar": "إيقاف مؤقت والإعدادات"},
	"language": {"en": "Language / اللغة", "ar": "اللغة / Language"},
	"lang_name": {"en": "English", "ar": "العربية"},
	"graphics": {"en": "Graphics Quality", "ar": "جودة الرسوميات"},
	"low": {"en": "Low (Fast)", "ar": "منخفضة"},
	"medium": {"en": "Medium", "ar": "متوسطة"},
	"high": {"en": "High", "ar": "عالية"},
	"master_vol": {"en": "Master Volume", "ar": "الصوت العام"},
	"music_vol": {"en": "Music Volume", "ar": "صوت الموسيقى"},
	"sfx_vol": {"en": "SFX Volume", "ar": "المؤثرات الصوتية"},
	"touch_controls": {"en": "Touch Controls", "ar": "أزرار اللمس"},
	"no_save": {"en": "Begin your adventure in Eldoria", "ar": "ابدأ مغامرتك في ربوع إلدوريا"},
	"gold": {"en": "Gold", "ar": "الذهب"},
	"hud_level": {"en": "Lv.", "ar": "مستوى"},
	"hud_gold": {"en": "Gold", "ar": "ذهب"},
	"hud_rank": {"en": "Guild Rank", "ar": "رتبة النقابة"},
	"hud_day": {"en": "Day", "ar": "اليوم"},
	"inventory": {"en": "Inventory & Equipment", "ar": "الحقيبة والتجهيز"},
	"character": {"en": "Hero Overview", "ar": "ملف البطل"},
	"skills": {"en": "Skill Tree", "ar": "شجرة المهارات"},
	"quests": {"en": "Quests", "ar": "المهام"},
	"journal": {"en": "Quest Journal", "ar": "سجل المهام"},
	"guild": {"en": "Guild", "ar": "النقابة"},
	"reputation": {"en": "Guild Reputation", "ar": "سمعة النقابة"},
	"register_guild": {"en": "Register as Rank F Adventurer", "ar": "التسجيل كمغامر رتبة F"},
	"guild_hall": {"en": "Eldoria Adventurers Guild", "ar": "نقابة مغامري إلدوريا"},
	"guild_register": {"en": "Register as Rank F Adventurer", "ar": "التسجيل كمغامر رتبة F"},
	"guild_promote": {"en": "Promote Guild Rank", "ar": "ترقية رتبة النقابة"},
	"guild_contracts": {"en": "Official Guild Contracts Board", "ar": "لوحة عقود النقابة"},
	"crafting": {"en": "Forge & Alchemy Crafting", "ar": "الحدادة والخيمياء"},
	"craft": {"en": "Craft Item", "ar": "تصنيع"},
	"map": {"en": "World Map", "ar": "الخريطة"},
	"shop": {"en": "Merchant Trade", "ar": "المتجر"},
	"buy": {"en": "Buy", "ar": "شراء"},
	"sell": {"en": "Sell", "ar": "بيع"},
	"equip": {"en": "Equip", "ar": "تجهيز"},
	"unequip": {"en": "Unequip", "ar": "خلع"},
	"use": {"en": "Use", "ar": "استخدام"},
	"drop": {"en": "Drop", "ar": "إلقاء"},
	"unlock": {"en": "Unlock Skill", "ar": "فتح المهارة"},
	"skill_points": {"en": "Skill Points", "ar": "نقاط المهارة"},
	"reset_skills": {"en": "Reset All Skills", "ar": "إعادة تعيين المهارات"},
	"reset_confirm": {"en": "Confirm Skill Reset", "ar": "تأكيد إعادة التعيين"},
	"branch_warrior": {"en": "Warrior", "ar": "المحارب"},
	"branch_mage": {"en": "Mage", "ar": "الساحر"},
	"branch_ranger": {"en": "Ranger", "ar": "الحارس"},
	"branch_survival": {"en": "Survival", "ar": "البقاء"},
	"screen_inventory": {"en": "Inventory & Equipment", "ar": "الحقيبة والتجهيز"},
	"screen_character": {"en": "Hero Attributes", "ar": "خصائص البطل"},
	"screen_skills": {"en": "Skill Tree", "ar": "شجرة المهارات"},
	"screen_journal": {"en": "Quest Journal", "ar": "سجل المهام"},
	"screen_guild": {"en": "Adventurers Guild", "ar": "نقابة المغامرين"},
	"screen_crafting": {"en": "Forge & Crafting", "ar": "الحدادة والتصنيع"},
	"screen_map": {"en": "Map of Eldoria", "ar": "خريطة إلدوريا"},
	"screen_shop": {"en": "Merchant", "ar": "المتجر"},
	"screen_pause": {"en": "Paused", "ar": "إيقاف مؤقت"},
	"btn_close": {"en": "Close", "ar": "إغلاق"},
	"btn_resume": {"en": "Resume", "ar": "استئناف"},
	"btn_save": {"en": "Save Game", "ar": "حفظ اللعبة"},
	"btn_load": {"en": "Load Game", "ar": "تحميل اللعبة"},
	"btn_main_menu": {"en": "Main Menu", "ar": "القائمة الرئيسية"},
	"btn_register_guild": {"en": "Register as Adventurer", "ar": "التسجيل كمغامر"},
	"btn_reset_skills": {"en": "Reset Skills", "ar": "إعادة تعيين المهارات"},
	"btn_confirm_reset": {"en": "Confirm Reset", "ar": "تأكيد الإعادة"},
	"btn_craft": {"en": "Craft", "ar": "تصنيع"},
}

static var _font_cached: Font = null
static var _font_bold_cached: Font = null

static func current_lang() -> String:
	return SettingsManager.language if SettingsManager != null else LANG_EN

static func is_rtl() -> bool:
	return current_lang() == LANG_AR

static func is_arabic() -> bool:
	return is_rtl()

static func t(key: String, fallback: String = "") -> String:
	var lang := current_lang()
	if STRINGS.has(key):
		var entry: Dictionary = STRINGS[key]
		if entry.has(lang):
			return String(entry[lang])
		if entry.has(LANG_EN):
			return String(entry[LANG_EN])
	return fallback if not fallback.is_empty() else key

static func tr_key(key: String) -> String:
	return t(key, key.capitalize())

static func apply_direction(control: Control) -> void:
	if control == null:
		return
	control.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_rtl() else Control.LAYOUT_DIRECTION_LTR

static func apply_rtl(control: Control) -> void:
	apply_direction(control)

static func ui_font(bold: bool = false) -> Font:
	return bold_font() if bold else primary_font()

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
