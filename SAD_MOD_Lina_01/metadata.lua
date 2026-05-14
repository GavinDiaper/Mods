return PlaceObj('ModDef', {
	'title', "Mod_Lina - Survivor Assistant",
	'description', "[h1]Mod Lina - Your AI Survivor Assistant[/h1]\n\nA three-tier AI-powered colony management assistant for Stranded: Alien Dawn.\n\n[h2]Features[/h2]\n[list]\n[*][b]Advisor Mode (A)[/b] - Passive monitoring with real-time alerts on survivor stress, hunger, resource levels, and stalled production.\n[*][b]Semi-Auto Mode (B)[/b] - Framework for conditional automation (future expansion).\n[*][b]Full Automation Mode (C)[/b] - Framework for advanced colony management (future expansion).\n[/list]\n\n[h2]Configuration[/h2]\nConfigure Lina via the in-game Mod_Lina settings panel:\n[list]\n[*]Select operation mode\n[*]Set alert thresholds for stress, hunger, and resource reserves\n[*]Configure notification behavior and cooldowns\n[*]Prepare API credentials for future AI integrations\n[/list]\n\n[h2]Requirements[/h2]\nNo dependencies. Works standalone.",
	'image', "Mod/ModLina01/Images/sad_commonlib.jpg",
	'last_changes', "Initial v1 release: Advisor Mode fully implemented, Semi-Auto and Full-Auto scaffolding.",
	'id', "ModLina01",
	'author', "Gavin",
	'version', 9,
	'lua_revision', 233360,
	'saved_with_revision', 373414,
	'code', {
		"Code/main.lua",
		"Code/ModLina_Core.lua",
		"Code/ModLina_Config.lua",
		"Code/ModLina_Notifications.lua",
		"Code/ModLina_Advisor.lua",
		"Code/ModLina_SemiAuto.lua",
		"Code/ModLina_FullAuto.lua",
		"Code/ModLina_Settings.lua",
		"Code/ModLina_SettingsUI.lua",
		"Code/ModLina_Integration.lua",
		"Code/ModLina_HUD.lua",
	},
	'loctables', {
		{
			filename = "Localization/English.csv",
			language = "English",
		},
		{
			filename = "Localization/French.csv",
			language = "French",
		},
		{
			filename = "Localization/German.csv",
			language = "German",
		},
		{
			filename = "Localization/Spanish.csv",
			language = "Spanish",
		},
		{
			filename = "Localization/Japanese.csv",
			language = "Japanese",
		},
		{
			filename = "Localization/Korean.csv",
			language = "Korean",
		},
		{
			filename = "Localization/Polish.csv",
			language = "Polish",
		},
		{
			filename = "Localization/BrazilianPortuguese.csv",
			language = "Brazilian Portuguese",
		},
		{
			filename = "Localization/Russian.csv",
			language = "Russian",
		},
		{
			filename = "Localization/SimplifiedChinese.csv",
			language = "Simplified Chinese",
		},
	},
	'has_data', true,
	'saved', 1778764450,
	'code_hash', -2900065075662280625,
})