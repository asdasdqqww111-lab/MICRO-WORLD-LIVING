class_name Localization
extends RefCounted
## Complete Bilingual Localization (English + Arabic RTL) for MICRO WORLD: LIVING — Eldoria Edition.
## Covers UI screens, HUD, 4 Hero Classes, Story Prologue, all 27 Items, all 11 Quests & Objectives,
## all 24 Skills, all 11 Creatures, and all 18 Living NPCs & Dialogues.

const LANG_EN := "en"
const LANG_AR := "ar"

const STRINGS := {
	"game_title": {"en": "MICRO WORLD: LIVING", "ar": "العالم المصغّر: الحياة"},
	"game_subtitle": {"en": "CHRONICLES OF ELDORIA", "ar": "سجلات إلدوريا"},
	"welcome_eldoria": {"en": "Welcome to Eldoria — speak with Elder Theron or visit the Adventurers Guild!", "ar": "مرحباً بك في إلدوريا — تحدّث مع الحكيم ثيرون أو توجّه إلى نقابة المغامرين!"},
	"new_game": {"en": "New Adventure", "ar": "مغامرة جديدة"},
	"continue": {"en": "Continue", "ar": "متابعة"},
	"continue_game": {"en": "Continue Adventure", "ar": "متابعة المغامرة"},
	"choose_hero": {"en": "Choose Your Hero & Class", "ar": "اختر بطلك وفئتك القتالية"},
	"hero_name": {"en": "Hero Name:", "ar": "اسم البطل:"},
	"hero_default_name": {"en": "Alden", "ar": "ألدن"},
	"begin_journey": {"en": "Begin Chronicle", "ar": "ابدأ الملحمة"},
	"skip_intro": {"en": "Skip Prologue", "ar": "تخطّي المقدمة"},
	"next_page": {"en": "Next ▸", "ar": "التالي ◂"},
	"enter_eldoria": {"en": "Enter Eldoria ⚔", "ar": "ادخل عالم إلدوريا ⚔"},
	"save_game": {"en": "Save Game", "ar": "حفظ اللعبة"},
	"load_game": {"en": "Load Game", "ar": "تحميل اللعبة"},
	"delete_save": {"en": "Delete Save Slot", "ar": "حذف ملف الحفظ"},
	"settings": {"en": "Settings", "ar": "الإعدادات"},
	"quit": {"en": "Quit", "ar": "خروج"},
	"quit_menu": {"en": "Save & Return to Main Menu", "ar": "حفظ والعودة للقائمة الرئيسية"},
	"close": {"en": "Close", "ar": "إغلاق"},
	"resume": {"en": "Resume Adventure", "ar": "استئناف المغامرة"},
	"paused": {"en": "Paused & Settings", "ar": "إيقاف مؤقت والإعدادات"},
	"language": {"en": "Language / اللغة", "ar": "اللغة / Language"},
	"lang_name": {"en": "English", "ar": "العربية"},
	"graphics": {"en": "Graphics Quality", "ar": "جودة الرسوميات"},
	"low": {"en": "Low (Fast)", "ar": "منخفضة (سريعة)"},
	"medium": {"en": "Medium", "ar": "متوسطة"},
	"high": {"en": "High", "ar": "عالية"},
	"master_vol": {"en": "Master Volume", "ar": "الصوت العام"},
	"music_vol": {"en": "Music Volume", "ar": "صوت الموسيقى"},
	"sfx_vol": {"en": "SFX Volume", "ar": "المؤثرات الصوتية"},
	"touch_controls": {"en": "Touch Controls", "ar": "أزرار اللمس"},
	"no_save": {"en": "Begin your adventure in Eldoria", "ar": "ابدأ مغامرتك في ربوع إلدوريا"},
	"gold": {"en": "Gold", "ar": "الذهب"},
	"hud_level": {"en": "Level", "ar": "المستوى"},
	"hud_gold": {"en": "Gold", "ar": "ذهب"},
	"hud_rank": {"en": "Rank", "ar": "الرتبة"},
	"hud_day": {"en": "Day", "ar": "اليوم"},
	"level": {"en": "Level", "ar": "المستوى"},
	"day": {"en": "Day", "ar": "اليوم"},
	"weather_clear": {"en": "Weather Clear", "ar": "الطقس صحو"},
	"weather_rain": {"en": "Weather Rain", "ar": "الطقس ممطر"},
	"hud_weather_clear": {"en": "Weather Clear", "ar": "الطقس صحو"},
	"hud_weather_rain": {"en": "Weather Rain", "ar": "الطقس ممطر"},
	"hud_target_locked": {"en": "◎ Target Locked", "ar": "◎ هدف مقفل"},
	"hud_waypoint": {"en": "◆ Objective", "ar": "◆ الهدف"},
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
	"guild_contracts": {"en": "Official Guild Contracts (Ranks F – S)", "ar": "لوحة عقود النقابة الرسمية (الرتب F – S)"},
	"crafting": {"en": "Forge & Alchemy Crafting", "ar": "الحدادة والخيمياء"},
	"craft": {"en": "Craft Item", "ar": "تصنيع"},
	"map": {"en": "World Map", "ar": "خريطة إلدوريا"},
	"shop": {"en": "Merchant Trade", "ar": "المتجر"},
	"buy": {"en": "Buy", "ar": "شراء"},
	"sell": {"en": "Sell", "ar": "بيع"},
	"accept": {"en": "Accept", "ar": "قبول"},
	"active": {"en": "Active", "ar": "نشطة"},
	"completed": {"en": "Completed", "ar": "مكتملة"},
	"equip": {"en": "Equip", "ar": "تجهيز"},
	"unequip": {"en": "Unequip", "ar": "خلع"},
	"use": {"en": "Use", "ar": "استخدام"},
	"drop": {"en": "Drop", "ar": "إلقاء"},
	"leave": {"en": "Leave", "ar": "مغادرة"},
	"unlock": {"en": "Unlock Skill", "ar": "فتح المهارة"},
	"skill_points": {"en": "Skill Points", "ar": "نقاط المهارة"},
	"reset_skills": {"en": "Reset All Skills", "ar": "إعادة تعيين المهارات"},
	"reset_confirm": {"en": "Confirm Skill Reset", "ar": "تأكيد إعادة التعيين"},
	"branch_warrior": {"en": "Warrior", "ar": "المحارب"},
	"branch_mage": {"en": "Mage", "ar": "الساحر"},
	"branch_ranger": {"en": "Ranger", "ar": "الحارس"},
	"branch_survival": {"en": "Survival", "ar": "النجاة"},
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

const ITEMS_AR := {
	"ancient_relic": {"name": "أثر إلدوريا العتيق", "desc": "قرص حجري منقوش يهمس بطاقة قديمة من أعماق السرداب."},
	"bone": {"name": "عظم هيكل", "desc": "بقايا هياكل عظمية؛ يشتريها الحداد والتجار."},
	"bread": {"name": "رغيف خبز القرية", "desc": "خبز طازج من فرن إلدوريا؛ يستعيد 12 نقطة صحة."},
	"crypt_crown": {"name": "تاج الملك الغارق", "desc": "خوذة مذهّبة أسطورية انتُزعت من سيد السرداب مالاكور."},
	"crypt_heart": {"name": "نواة السرداب المظلم", "desc": "بلورة نابضة من قلب مالاكور، لازمة لصياغة الأسلحة الأسطورية."},
	"eldoria_mythic_blade": {"name": "نصل شمس إلدوريا", "desc": "سيف أسطوري منقوش بأحرف الفجر؛ ذروة صناعة حدّادي إلدوريا."},
	"guild_aegis": {"name": "ترس شعار النقابة", "desc": "ترس مهيب مصقول للمعارك يُمنح لرتب المغامرين المتقدمة."},
	"guild_ring": {"name": "خاتم المغامر الأثيري", "desc": "خاتم فضي بختم النقابة يعزّز القوة والتركيز السحري."},
	"health_potion": {"name": "جرعة الصحة", "desc": "مستخلص أعشاب حمراء مركّز؛ يستعيد 40 نقطة صحة فوراً."},
	"herb_moonpetal": {"name": "زهرة بتلة القمر", "desc": "زهرة لازوردية متوهجة تنمو قرب بحيرة الكريستال والأجمة المقدسة."},
	"herb_redcap": {"name": "عشبة القلنسوة الحمراء", "desc": "فطر قرمزي نادر من أطراف الغابة يستخدمه المعالجون والخيميائيون."},
	"iron_helmet": {"name": "خوذة حديدية", "desc": "خوذة فولاذية متينة تحمي الرأس من ضربات السيوف والسهام."},
	"iron_ingot": {"name": "سبيكة حديد", "desc": "حديد مصهور نقي جاهز للطرق على سندان الحدادة."},
	"iron_ore": {"name": "خام الحديد", "desc": "خام معدني مستخرج من صخور المرتفعات الشرقية."},
	"iron_shield": {"name": "ترس الفارس الحديدي", "desc": "ترس ثقيل مقوّى يصد أعنف الضربات في المعارك."},
	"iron_sword": {"name": "سيف حديدي مصقول", "desc": "سيف متوازن طرقه حداد القرية غريم؛ حاد الشفرة وموثوق."},
	"knight_plate": {"name": "درع فارس الطليعة", "desc": "درع فولاذي مفصلي مع عباءة ملكية من طراز حرس إلدوريا."},
	"leather_armor": {"name": "درع جلدي مقوّى", "desc": "صفائح جلدية معالجة تمنح حماية خفيفة وحركة صامتة."},
	"mana_elixir": {"name": "إكسير المانا", "desc": "شراب مقطّر من زهرة القمر يستعيد 45 نقطة مانا."},
	"oak_shield": {"name": "ترس البلوط المستدير", "desc": "ترس من خشب البلوط المطوّق بالحديد لكشّافة إلدوريا."},
	"rusty_sword": {"name": "سيف صدئ", "desc": "نصل قديم من ورشة القرية؛ بداية متواضعة لكل مغامر."},
	"skeleton_key": {"name": "مفتاح عظمي", "desc": "مفتاح حديدي بارد منحوت على هيئة عظمة قديمة."},
	"slime_gel": {"name": "هلام السلايم", "desc": "مادة هلامية خضراء لامعة مطلوبة في وصفات الخيمياء."},
	"steel_greatsword": {"name": "سيف المرتفعات العظيم", "desc": "سيف فولاذي ضخم بقبضتين يمنح مدى واسعاً وضربات قاضية."},
	"venison": {"name": "لحم غزال مشوي", "desc": "وجبة صياد غنية تستعيد الصحة والنشاط معاً."},
	"wolf_pelt": {"name": "فرو الذئب الرمادي", "desc": "فرو كثيف متين يُباع بسعر جيد ويدخل في صناعة الدروع."},
	"wood": {"name": "أخشاب الغابة", "desc": "جذوع مشذّبة من حافة الغابة الغربية لصناعة التروس والمعدات."},
}

const SKILLS_AR_DESC := {
	"mighty_blow": "+2.5 هجوم قريب لكل رتبة. حجر الأساس في قتال السيوف.",
	"iron_skin": "+2.0 دفاع لكل رتبة. يصلّب وقفتك أمام ضربات الأعداء.",
	"heavy_cleave": "+18% ضرر إضافي للضربة الثقيلة الدوّارة لكل رتبة.",
	"shield_mastery": "+10% تقليل للضرر أثناء الصد بالترس وتخفيض استهلاك النشاط.",
	"lethal_precision": "+5% فرصة ضربة حرجة لكل رتبة.",
	"berserker_rage": "+15% هجوم و+20 صحة قصوى لكل رتبة؛ يضاعف شراستك في القتال.",
	"fire_bolt": "يطلق ويعزّز تعويذة لهب النار (+4 قوة سحرية لكل رتبة).",
	"mana_flow": "-12% تكلفة مانا للتعاويذ و+15 مانا قصوى لكل رتبة.",
	"frost_nova": "يشبع التعاويذ بصقيع الجليد (+4.5 قوة سحرية وإبطاء حركة الأعداء).",
	"arcane_potency": "+5.0 قوة سحرية وتجدد أسرع للمانا لكل رتبة.",
	"storm_lance": "يطلق صواعق برق خاطفة بعيدة المدى (+6 قوة سحرية لكل رتبة).",
	"elemental_mastery": "+22% ضرر إضافي لجميع التعاويذ العنصرية لكل رتبة.",
	"swift_feet": "+6% سرعة حركة وعدو سريع لكل رتبة.",
	"bow_mastery": "+2.2 رشاقة وقوة هجوم دقيقة لكل رتبة.",
	"shadow_step": "-15% استهلاك نشاط للمراوغة وزيادة فترة المناعة أثناء التدحرج.",
	"eagle_eye": "+18% مضاعف ضرر الضربات الحرجة لكل رتبة.",
	"snare_trap": "تُبطئ هجماتك الأعداء وتلحق +12% ضرراً إضافياً بالأهداف المشتبكة.",
	"beast_bane": "+20% ضرر إضافي ضد جميع الوحوش وزعماء الزنازين.",
	"vital_endurance": "+20 صحة قصوى و+10 نشاط أقصى لكل رتبة.",
	"keen_gatherer": "+1 مورد إضافي عند حصاد المعادن أو الأخشاب أو الأعشاب.",
	"master_hunter": "+15% ذهب وغنائم إضافية من الوحوش المهزومة لكل رتبة.",
	"artisan_smith": "شحنات إضافية عند تصنيع الجرعات وكفاءة أعلى في الحدادة.",
	"pathfinder": "+12% خبرة وسمعة نقابة إضافية من جميع المهام والمعارك.",
	"resource_thrift": "+25% فعالية جرعات الصحة والمانا و+25% سرعة تجدد النشاط.",
}

const QUESTS_AR := {
	"main_guild_call": {
		"title": "نداء نقابة المغامرين",
		"desc": "يطلب الحكيم ثيرون منك زيارة القاعة الكبرى لنقابة المغامرين شمال ساحة إلدوريا والتسجيل لدى موظفة الاستقبال إيلينا.",
		"objs": ["ادخل قاعة نقابة المغامرين الكبرى"],
	},
	"skeleton_menace": {
		"title": "خطر الهياكل العظمية",
		"desc": "تتسلل الهياكل العظمية من الغابة الغربية كل ليلة لتهديد مزارع القرية. اقضِ على 3 منها وعد إلى المزارعة ميرا.",
		"objs": ["الهياكل العظمية المهزومة"],
	},
	"sunken_cellar": {
		"title": "القبو الغارق",
		"desc": "انفتح مدخل السرداب القديم شرق القرية وسرق الموتى الأثر العتيق للحرس. طهّر السرداب واستعد الأثر للحارس أوسك.",
		"objs": ["هياكل السرداب المدمّرة", "استعادة أثر إلدوريا العتيق"],
	},
	"smith_ore_supply": {
		"title": "حديد لورشة الحدادة",
		"desc": "يحتاج الحداد غريم إلى خام الحديد من الصخور الشرقية لإشعال كور الحدادة. اجمع 3 قطع خام حديد وعد إليه.",
		"objs": ["خام الحديد المجموع"],
	},
	"healer_herbs": {
		"title": "بلسم الغابة الشافي",
		"desc": "تحتاج المعالجة سيرا في الكنيسة إلى 3 أعشاب قلنسوة حمراء من أطراف الغابة الغربية لمداواة الجرحى.",
		"objs": ["أعشاب القلنسوة الحمراء"],
	},
	"main_dread_crypt": {
		"title": "الظل الكامن تحت إلدوريا",
		"desc": "يحذّر القائد الأعلى ألدريك من صحوة مالاكور سيد السرداب المظلم تحت الأطلال الشرقية. اهبط إلى السرداب الغارق وأنهِ تهديده.",
		"objs": ["اهبط إلى السرداب الغارق", "اهزم مالاكور سيد السرداب المظلم"],
	},
	"contract_forest_cull": {
		"title": "[رتبة F] تطهير مطاردي الأشواك",
		"desc": "عقد صيد رسمي: يهاجم مطاردو الأشواك الحطّابين في الغابة الغربية. اقضِ على اثنين منهم.",
		"objs": ["مطاردي الأشواك المهزومين"],
	},
	"contract_herb_harvest": {
		"title": "[رتبة F] قطاف بتلات القمر",
		"desc": "عقد جمع رسمي: اقطف زهرتين من بتلات القمر حول بحيرة الكريستال لصالح أمين مستودع النقابة برام.",
		"objs": ["بتلات القمر المقطوفة"],
	},
	"contract_ruins_survey": {
		"title": "[رتبة E] استطلاع الأطلال الشرقية",
		"desc": "عقد استكشاف: اعبر الجسر الحجري فوق النهر، واستطلع الأطلال القديمة واطرد طيف الأطلال النخبوي.",
		"objs": ["بلوغ الأطلال الشرقية", "طرد طيف الأطلال"],
	},
	"contract_bridge_escort": {
		"title": "[رتبة D] تأمين ممر ناب الظل",
		"desc": "عقد حراسة ودورية: طهّر خفاشين من خفافيش ناب الظل تهدد طريق القوافل قرب الكهف الشمالي.",
		"objs": ["خفافيش ناب الظل المهزومة"],
	},
	"contract_crypt_lord": {
		"title": "[رتبة C] مكافأة الزنزانة: سيد السرداب",
		"desc": "عقد زنزانة رسمي: اقتحم السرداب الغارق واقضِ على الزعيم مالاكور سيد السرداب المظلم.",
		"objs": ["القضاء على مالاكور سيد السرداب"],
	},
}

const CREATURES_AR := {
	"slime": "سلايم زمردي",
	"wolf": "ذئب الغابة",
	"meadow_stag": "أيل المرتفعات",
	"forest_goblin": "مطارد الأشواك",
	"skeleton_forest": "هيكل عظمي",
	"skeleton_dungeon": "هيكل السرداب",
	"cave_bat": "خفاش ناب الظل",
	"rock_golem": "حارس الغرانيت الصخري",
	"wraith_elite": "طيف الأطلال (نخبة)",
	"grove_guardian": "حارس الأجمة القديمة (نخبة)",
	"crypt_boss": "مالاكور، سيد السرداب المظلم",
}

const NPCS_AR := {
	"blacksmith": {
		"name": "غريم", "title": "كبير الحدّادين",
		"lines": [
			"لا يهدأ سنداني من الفجر حتى الغروب! أحضر لي خام الحديد أو استخدم كور الحدادة متى شئت.",
			"ترس متين ونصل مصقول هما خير رفيق لك في ظلمات السرداب الغارق."
		],
	},
	"farmer": {
		"name": "ميرا", "title": "مزارعة الطاحونة",
		"lines": [
			"تسللت الهياكل العظمية مجدداً من الغابة الغربية الليلة الماضية!",
			"قمحنا الذهبي يطعم أهل إلدوريا جميعاً — ساعدنا على تأمين الحقول والطرقات."
		],
	},
	"guard": {
		"name": "أوسك", "title": "قائد حرس البوابة الشرقية",
		"lines": [
			"وراء جسر الحجر تقع الأطلال القديمة ومدخل السرداب الغارق؛ لا تعبر دون سلاح وترس.",
			"إذا استعدت أثر الحرس العتيق من السرداب فسأكافئك بسخاء."
		],
	},
	"elder": {
		"name": "الحكيم ثيرون", "title": "كبير حكماء إلدوريا",
		"lines": [
			"أهلاً بك في ساحة إلدوريا يا بني. منذ أن اهتزت أختام السرداب الشرقي والوحوش تقترب من أسوارنا.",
			"توجه شمال الساحة إلى قاعة نقابة المغامرين الكبرى وسجّل اسمك لتبدأ رحلتك الرسمية."
		],
	},
	"merchant": {
		"name": "طارق", "title": "تاجر القوافل",
		"lines": [
			"بضائع طازجة وجرعات وأسلحة من شتى بقاع المملكة! كلما ارتفعت رتبتك في النقابة حصلت على خصم أكبر.",
			"أسعار السوق تتغير كل صباح حسب وفرة الغنائم وحالة الطرق."
		],
	},
	"healer": {
		"name": "الأخت سيرا", "title": "معالجة المعبد",
		"lines": [
			"نور المعبد يشفي الجراح ويعيد الصفاء لروحك؛ اطلب البركة متى أرهقتك المعارك.",
			"أبحث دوماً عن أعشاب القلنسوة الحمراء لتحضير جرعات الشفاء للحرس."
		],
	},
	"innkeeper": {
		"name": "مارتا", "title": "صاحبة نُزل الموقد",
		"lines": [
			"نار الموقد دافئة والسرير مريح؛ يمكنك الاستراحة حتى الفجر مقابل 10 قطع ذهبية فقط.",
			"يتحدث المسافرون عن غرفة سرية مخفية في الجدار الشرقي داخل السرداب الغارق!"
		],
	},
	"south_guard": {
		"name": "فاريك", "title": "حارس البوابة الجنوبية",
		"lines": [
			"البوابة الجنوبية تطل على المروج وبحيرة الكريستال؛ انتبه للذئاب عند حلول الغسق.",
			"احرص على قفل الهدف (LCK) أثناء الاشتباك مع أكثر من عدو."
		],
	},
	"hunter": {
		"name": "روان", "title": "صيّاد الغابات",
		"lines": [
			"الأيائل في المروج مسالمة وسريعة الجفل، أما ذئاب الغابة الغربية فتصطاد في قطعان.",
			"مهارات فرع الحارس تمنحك سرعة فائقة وضربات حرجة قاتلة."
		],
	},
	"apprentice": {
		"name": "توما", "title": "تلميذ الحدّاد",
		"lines": [
			"أتعلّم طرق الفولاذ على يد المعلّم غريم! جرّب طاولة التصنيع لصياغة السيوف والتروس.",
			"جمع الأخشاب وخام الحديد من البراري أوفر كثيراً من الشراء."
		],
	},
	"child": {
		"name": "بيب", "title": "فتى القرية",
		"lines": [
			"هل أنت مغامر حقيقي من النقابة؟ حلمي أن أحصل على شارة الرتبة S يوماً ما!",
			"رأيت زهوراً زرقاء تضيء ليلاً عند شاطئ بحيرة الكريستال!"
		],
	},
	"traveler": {
		"name": "فاين", "title": "باحث رحّالة",
		"lines": [
			"درست نقوش إلدوريا القديمة؛ مالاكور في السرداب الغارق يزداد ضراوة حين تنخفض صحته للنصف!",
			"الخفافيش قرب الكهف الشمالي تعرقل قافلتي — راجع لوحة عقود النقابة إن أردت المساعدة."
		],
	},
	"guild_receptionist": {
		"name": "إيلينا", "title": "مسؤولة استقبال النقابة",
		"lines": [
			"مرحباً بك في قاعة نقابة مغامري إلدوريا! سجّل اسمك لتحصل على شارة الرتبة F وتبدأ قبول العقود الرسمية.",
			"إنجاز العقود يرفع سمعتك ويؤهلك للترقية من الرتبة F حتى الرتبة الأسطورية S!"
		],
	},
	"guild_master": {
		"name": "القائد الأعلى ألدريك", "title": "سيد نقابة المغامرين",
		"lines": [
			"تأسست نقابتنا لحماية إلدوريا من أخطار الأعماق. أثبت جدارتك في الميدان وسأفتح لك أخطر العقود.",
			"الظلام المتصاعد من السرداب الغارق ينذر بعودة مالاكور؛ استعد جيداً قبل النزول."
		],
	},
	"quartermaster": {
		"name": "برام", "title": "أمين مستودع النقابة",
		"lines": [
			"مستودع النقابة مجهّز بالجرعات والدروع النادرة للمغامرين المسجّلين.",
			"ترقيتك في رتب النقابة تمنحك خصماً دائماً لدى جميع التجار!"
		],
	},
	"combat_trainer": {
		"name": "المعلّم كايل", "title": "مدرّب القتال والمهارات",
		"lines": [
			"كل مستوى جديد يمنحك نقطة مهارة؛ وزّعها بحكمة بين المحارب والساحر والحارس والنجاة.",
			"اضغط على الصد (BLK) لتخفيف الضرر أو المراوغة (DGE) لتفادي ضربات الزعماء القاضية!"
		],
	},
	"veteran_lyra": {
		"name": "ليرا", "title": "مغامرة مخضرمة — رتبة B",
		"lines": [
			"نصيحة من مغامرة رتبة B: سحر الجليد يُبطئ الأعداء المدرّعين ويمنحك أفضلية حاسمة.",
			"لا تفوّت الحجرة السرية الشرقية داخل السرداب الغارق؛ فيها صندوق كنز ثمين!"
		],
	},
	"recruit_finn": {
		"name": "فين", "title": "مجند مبتدئ — رتبة F",
		"lines": [
			"حصلت اليوم على شارة الرتبة F! سأبدأ بعقد قطاف بتلات القمر عند بحيرة الكريستال.",
			"حالما أصنع سيفاً حديدياً عند الحداد غريم سأنطلق لتطهير الغابة الغربية!"
		],
	},
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

# --- Content Localization Helpers --------------------------------------------

static func item_name(item: ItemData) -> String:
	if item == null:
		return ""
	if is_arabic() and ITEMS_AR.has(item.id):
		return String((ITEMS_AR[item.id] as Dictionary).get("name", item.display_name))
	return item.display_name

static func item_desc(item: ItemData) -> String:
	if item == null:
		return ""
	if is_arabic() and ITEMS_AR.has(item.id):
		return String((ITEMS_AR[item.id] as Dictionary).get("desc", item.description))
	return item.description

static func skill_title(skill: SkillData) -> String:
	if skill == null:
		return ""
	if is_arabic() and not skill.title_ar.is_empty():
		return skill.title_ar
	return skill.title

static func skill_desc(skill: SkillData) -> String:
	if skill == null:
		return ""
	if is_arabic() and SKILLS_AR_DESC.has(skill.id):
		return String(SKILLS_AR_DESC[skill.id])
	return skill.description

static func quest_title(quest: QuestData) -> String:
	if quest == null:
		return ""
	if is_arabic() and QUESTS_AR.has(quest.id):
		return String((QUESTS_AR[quest.id] as Dictionary).get("title", quest.title))
	return quest.title

static func quest_desc(quest: QuestData) -> String:
	if quest == null:
		return ""
	if is_arabic() and QUESTS_AR.has(quest.id):
		return String((QUESTS_AR[quest.id] as Dictionary).get("desc", quest.description))
	return quest.description

static func quest_obj_label(quest: QuestData, index: int, fallback: String = "") -> String:
	if quest == null:
		return fallback
	if is_arabic() and QUESTS_AR.has(quest.id):
		var objs: Array = (QUESTS_AR[quest.id] as Dictionary).get("objs", [])
		if index >= 0 and index < objs.size():
			return String(objs[index])
	if index >= 0 and index < quest.objectives.size():
		return String((quest.objectives[index] as Dictionary).get("label", fallback))
	return fallback

static func creature_name(creature: CreatureData) -> String:
	if creature == null:
		return ""
	if is_arabic() and CREATURES_AR.has(creature.id):
		return String(CREATURES_AR[creature.id])
	return creature.display_name

static func npc_name(npc_id: String, fallback: String) -> String:
	if is_arabic() and NPCS_AR.has(npc_id):
		return String((NPCS_AR[npc_id] as Dictionary).get("name", fallback))
	return fallback

static func npc_title(npc_id: String, fallback: String) -> String:
	if is_arabic() and NPCS_AR.has(npc_id):
		return String((NPCS_AR[npc_id] as Dictionary).get("title", fallback))
	return fallback

static func npc_lines(npc_id: String, fallback: Array) -> Array:
	if is_arabic() and NPCS_AR.has(npc_id):
		return ((NPCS_AR[npc_id] as Dictionary).get("lines", fallback) as Array).duplicate()
	return fallback

static func class_title(class_id: String) -> String:
	var def := HeroClassDB.get_class_def(class_id)
	return String(def.get("title_ar" if is_arabic() else "title_en", class_id.capitalize()))

static func class_desc(class_id: String) -> String:
	var def := HeroClassDB.get_class_def(class_id)
	return String(def.get("desc_ar" if is_arabic() else "desc_en", ""))

static func prologue_slides() -> Array[Dictionary]:
	if is_arabic():
		return [
			{
				"chapter": "الفصل الأول · وادي إلدوريا الأخضر",
				"title": "سلامٌ تهزّه نذر الأعماق",
				"body": "قروناً طويلة عاشت قرية إلدوريا آمنةً بين قمم الشمال المكسوّة بالثلوج وضفاف بحيرة الكريستال، تحرسها منارات نقابة المغامرين وتطعمها حقول القمح الذهبية.",
			},
			{
				"chapter": "الفصل الثاني · انكسار ختم السرداب",
				"title": "صحوة مالاكور سيد السرداب الغارق",
				"body": "قبل ليالٍ معدودات، تصدّعت الأحجار القديمة شرق الجسر الحجري، وخرجت الهياكل العظمية وأطياف الأطلال تجوب الغابات، فيما يتردد صدى تعاويذ مالاكور تحت الأرض.",
			},
			{
				"chapter": "الفصل الثالث · نداء نقابة المغامرين",
				"title": "ملحمتك تبدأ اليوم في ساحة إلدوريا",
				"body": "أرسل الحكيم ثيرون والقائد الأعلى ألدريك نداء النفير إلى كل بطل جسور: سجّل اسمك في نقابة المغامرين، اصقل سلاحك ومهاراتك، واهبط إلى السرداب الغارق لتعيد النور إلى إلدوريا!",
			},
		]
	return [
		{
			"chapter": "Chapter I · The Emerald Vale of Eldoria",
			"title": "A Peace Trembling on the Brink",
			"body": "For generations, Eldoria Village prospered between snow-crowned northern peaks and the shimmering waters of Crystal Lake, warded by the banners of the Adventurers Guild.",
		},
		{
			"chapter": "Chapter II · The Shattered Seal",
			"title": "Stirring of the Sunken Crypt",
			"body": "Three nights ago, ancient wards east of the stone river bridge cracked open. Restless skeletons and Bramble Stalkers now prowl the woods as Dread Lord Malakor gathers power below.",
		},
		{
			"chapter": "Chapter III · Call of the Guild",
			"title": "Your Chronicle Begins Now",
			"body": "Elder Theron and Grandmaster Aldric have sounded the call across the realm: register at the Adventurers Guild Hall, master steel and arcane craft, and descend into the Sunken Crypt!",
		},
	]

# --- Layout & Font Helpers ---------------------------------------------------

static func apply_direction(control: Control) -> void:
	if control == null:
		return
	control.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_rtl() else Control.LAYOUT_DIRECTION_LTR

static func apply_rtl(control: Control) -> void:
	apply_direction(control)

static func ui_font(bold: bool = false) -> Font:
	return active_font(bold)

static func active_font(bold: bool = false) -> Font:
	var cairo_path := "res://assets/ui/fonts/Cairo-Variable.ttf"
	if ResourceLoader.exists(cairo_path):
		var cf := load(cairo_path) as Font
		if cf != null:
			return cf
	var lang := current_lang()
	var path := ""
	if lang == LANG_AR:
		path = "res://assets/ui/fonts/NotoSansArabic-Medium.ttf"
	else:
		path = "res://assets/ui/fonts/NotoSans-Bold.ttf" if bold else "res://assets/ui/fonts/NotoSans-Medium.ttf"
	if ResourceLoader.exists(path):
		var f := load(path) as Font
		if f != null:
			return f
	return ThemeDB.fallback_font
