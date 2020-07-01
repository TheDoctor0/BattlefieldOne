#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csx>
#include <engine>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <sqlx>
#include <unixtime>
#include <stripweapons>
#include <bf1>

#define PLUGIN "Battlefield One Mod"
#define VERSION "2.2"
#define AUTHOR "O'Zone"

#define MAX_RANKS 17
#define MAX_BONUSRANKS 7
#define MAX_BADGES 10
#define MAX_ORDERS 10
#define MAX_LEVELS 4
#define MAX_DEGREES 5

#define TASK_HUD 9876
#define TASK_HELP 8765
#define TASK_GLOW 7654
#define TASK_FROST 6543
#define TASK_TIME 5432
#define TASK_AD 5432

#define LOG_FILE "BF1.log"

new const weaponNames[][] = { "weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
"weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
"weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90" }

new const cmdMainMenu[][] = { "bf1", "say /bf1", "say_team /bf1", "say /bf1menu", "say_team /bf1menu", "say /bf2", "say_team /bf2", "say /bf2menu", "say_team /bf2menu" };
new const cmdHelp[][] = { "pomoc", "say /pomoc", "say_team /pomoc", "say /help", "say_team /help" };
new const cmdHelpMenu[][] = { "pomocmenu", "say /pomocmenu", "say_team /pomocmenu", "say /helpmenu", "say_team /helpmenu" };
new const cmdBadges[][] = { "odznaki", "say /odznaki", "say_team /odznaki", "say /badges", "say_team /badges" };
new const cmdOrders[][] = { "ordery", "say /ordery", "say_team /ordery", "say /orders", "say_team /orders" };
new const cmdRanks[][] = { "rangi", "say /rangi", "say_team /rangi", "say /ranks", "say_team /ranks" };
new const cmdPlayers[][] = { "gracze", "say /gracze", "say_team /gracze", "say /kto", "say_team /kto", "say /players", "say_team /players", "say /who", "say_team /who" };
new const cmdStats[][] = { "staty", "say /staty", "say_team /staty", "say /stats", "say_team /stats", "say /bf1stats", "say_team /bf1stats" };
new const cmdStatsMenu[][] = { "statymenu", "say /statymenu", "say_team /statymenu", "say /statsmenu", "say_team /statsmenu" };
new const cmdStatsServer[][] = { "statyserwer", "say /statyserwer", "say_team /statyserwer", "say /statsserver", "say_team /statsserver", "say /serverstats", "say_team /serverstats" };
new const cmdHud[][] = { "hud", "say /hud", "say_team /hud", "say /zmienhud", "say_team /zmienhud", "say /changehud", "say_team /changehud" };
new const cmdTime[][] = { "czas", "say /czas", "say_team /czas", "say /time", "say_team /time" };
new const cmdTimeTop[][] = { "topczas", "say /topczas", "say_team /topczas", "say /toptime", "say_team /toptime", "say /ctop15", "say_team /ctop15", "say /ttop15", "say_team /ttop15" };
new const cmdTimeMenu[][] = { "czasmenu", "say /czasmenu", "say_team /czasmenu", "say /timemenu", "say_team /timemenu" };
new const cmdDegrees[][] = { "stopnie", "say /stopnie", "say_team /stopnie", "say /degrees", "say_team /degrees", "say /stopien", "say_team /stopien", "say /degree", "say_team /degree" };

enum _:playerInfo {
	KILLS, HS_KILLS, ASSISTS, GOLD, SILVER, BRONZE, HUD, HUD_RED, HUD_GREEN, HUD_BLUE, HUD_POSX, HUD_POSY, DEGREE, ADMIN, TIME, VISITS, FIRST_VISIT, LAST_VISIT, KNIFE, PISTOL, GLOCK, USP, P228,
	DEAGLE, FIVESEVEN, ELITES, SNIPER, SCOUT, AWP, G3SG1, SG550, RIFLE, AK47, M4A1, GALIL, FAMAS, SG552, AUG, M249, SMG, MAC10, TMP, MP5, UMP45, P90, GRENADE, SHOTGUN, M3, XM1014, PLANTS, EXPLOSIONS,
	DEFUSES, RESCUES, SURVIVED, DMG_TAKEN, DMG_RECEIVED, EARNED, MONEY, MENU, RANK, NEXT_RANK, BADGES_COUNT, ORDERS_COUNT, NAME[32], SAFE_NAME[32], BADGES[MAX_BADGES], ORDERS[MAX_ORDERS]
};

new bf1Player[MAX_PLAYERS + 1][playerInfo];

enum _:sounds { SOUND_RANKUP, SOUND_ORDER, SOUND_BADGE, SOUND_PACKAGE, SOUND_LOAD, SOUND_GRENADE };

new const bf1Sounds[][] =
{
	"bf1/rankup.wav",
	"bf1/orderget.wav",
	"bf1/badgeget.wav",
	"bf1/packageget.wav",
	"bf1/getin.wav",
	"items/9mmclip1.wav"
};

enum _:resources { MODEL_PACKAGE, SPRITE_GREEN, SPRITE_ACID }

new const bf1Resources[][] =
{
	"models/bf1/package_item.mdl",
	"sprites/bf1/green.spr",
	"sprites/bf1/acid_pou.spr"
};

new bf1Resource[sizeof(bf1Resources)];

new sprites[MAX_RANKS + MAX_BONUSRANKS];

enum _:degreeInfo { DEGREES, DESC, HOURS };

new bf1Degrees[MAX_DEGREES][degreeInfo][] =
{
	{ "Przybysz", 		"Stopien I, Przybysz.", 									"0" },
	{ "Bywalec", 		"Stopien II, Bywalec, powyzej 8 godzin czasu gry.", 		"8" },
	{ "Staly Gracz", 	"Stopien III, Staly Gracz, powyzej 24 godzin czasu gry.", 	"24" },
	{ "Bohater", 		"Stopien IV, Bohater, powyzej 50 godzin czasu gry.", 		"50" },
	{ "Legenda", 		"Stopien V, Legenda, powyzej 100 godzin czasu gry.", 		"100" }
};

enum _:orders {
	ORDER_AIMBOT, ORDER_ANGEL, ORDER_BOMBERMAN, ORDER_SAPER, ORDER_PERSIST,
	ORDER_DESERV, ORDER_MILION, ORDER_BULLET, ORDER_RAMBO, ORDER_SURVIVER
};

enum _:orderInfo { DESIGNATION, NEEDS };

new bf1Orders[MAX_ORDERS][orderInfo][] = {
	{ "Aimboter", 		"Zabij 2500 razy przez trafienie w glowe" },
	{ "Aniol Stroz", 	"Zalicz 500 asyst" },
	{ "Bomberman", 		"Podloz 100 bomb" },
	{ "Saper", 			"Rozbroj 50 bomb" },
	{ "Wytrwaly", 		"Odwiedz serwer 100 razy" },
	{ "Zasluzony", 		"Zdobadz 100 medali" },
	{ "Milioner", 		"Zarob 1 milion dolarow" },
	{ "Kuloodporny", 	"Otrzymaj 50.000 obrazen" },
	{ "Rambo", 			"Zadaj 50.000 obrazen" },
	{ "Niedobitek", 	"Przetrwaj 1000 rund" }
};

enum _:server {
	HIGHESTSERVERRANK, MOSTSERVERKILLS, MOSTSERVERWINS, HIGHESTSERVERRANKNAME[MAX_LENGTH], MOSTSERVERKILLSNAME[MAX_LENGTH], MOSTSERVERWINSNAME[MAX_LENGTH], MOSTSERVERKILLSID,
	HIGHESTRANK, HIGHESTRANKID, HIGHESTRANKNAME[MAX_LENGTH], MOSTKILLS, MOSTKILLSID, MOSTKILLSNAME[MAX_LENGTH], MOSTWINS, MOSTWINSID, MOSTWINSNAME[MAX_LENGTH],
}

new bf1Server[server];

new const bf1RankName[MAX_RANKS + MAX_BONUSRANKS][] = {
	"Szeregowy",			//0
	"Starszy Szeregowy",	//1
	"Kapral",				//2
	"Starszy Kapral",		//3
	"Plutonowy",			//4
	"Sierzant",				//5
	"Starszy Sierzant",		//6
	"Mlodszy Chorazy",		//7
	"Chorazy",				//8
	"Starszy Chorazy",		//9
	"Chorazy Sztabowy",		//10
	"Podporucznik",			//11
	"Porucznik",			//12
	"Kapitan",				//13
	"Major",				//14
	"Podpulkownik",			//15
	"Pulkownik",			//16
	"General Brygady",		//17
	"General Dywizji",		//18
	"General Korpusu",		//19
	"General Armii",		//20
	"Marszalek Polski",		//21
	"Marszalek Europy",		//22
	"Marszalek Swiata"		//23
};

new const Float:bf1RankOrder[MAX_RANKS + MAX_BONUSRANKS] = {
	0.0,
	1.0,
	2.0,
	3.0,
	4.0,
	5.0,
	6.0,
	7.0,
	8.0,
	9.0,
	10.0,
	11.0,
	12.0,
	13.0,
	14.0,
	15.0,
	16.0,
	7.5,
	8.5,
	15.5,
	20.0,
	21.0,
	22.0,
	23.0
};

new const bf1RankKills[MAX_RANKS + 1] = {
	0,		//0
	25,		//1
	50,		//2
	100,	//3
	250,	//4
	500,	//5
	1000,	//6
	2000,	//7
	3000,	//8
	4000,	//9
	5000,	//10
	6500,	//11
	8000,	//12
	9500,	//13
	11000,	//14
	12500,	//15
	15000	//16
};

enum _:badgesList {
	BADGE_KNIFE, BADGE_PISTOL, BADGE_ASSAULT, BADGE_SNIPER, BADGE_SUPPORT,
	BADGE_EXPLOSIVES, BADGE_SHOTGUN, BADGE_SMG, BADGE_TIME, BADGE_GENERAL
};

enum _:levelsList { LEVEL_NONE, LEVEL_START, LEVEL_EXPERIENCED, LEVEL_VETERAN, LEVEL_MASTER };

new const bf1BadgeName[MAX_BADGES][levelsList][] = {
	{ "", "Nowicjusz w Walce Nozem", "Doswiadczony w Walce Nozem", "Weteran w Walce Nozem", "Mistrz w Walce Nozem" },
	{ "", "Nowicjusz w Walce Pistoletem", "Doswiadczony w Walce Pistoletem", "Weteran w Walce Pistoletem", "Mistrz w Walce Pistoletem" },
	{ "", "Nowicjusz w Walce Bronia Szturmowa", "Doswiadczony w Walce Bronia Szturmowa", "Weteran w Walce Bronia Szturmowa", "Mistrz w Walce Bronia Szturmowa" },
	{ "", "Nowicjusz w Walce Bronia Snajperska", "Doswiadczony w Walce Bronia Snajperska", "Weteran w Walce Bronia Snajperska", "Mistrz w Walce Bronia Snajperska" },
	{ "", "Nowicjusz w Walce Bronia Wsparcia", "Doswiadczony w Walce Bronia Wsparcia", "Weteran w Walce Bronia Wsparcia", "Mistrz w Walce Bronia Wsparcia" },
	{ "", "Nowicjusz w Walce Granatami", "Doswiadczony w Walce Granatami", "Weteran w Walce Granatami", "Mistrz w Walce Granatami" },
	{ "", "Nowicjusz w Walce Shotgunami", "Doswiadczony w Walce Shotgunami", "Weteran w Walce Shotgunami", "Mistrz w Walce Shotgunami" },
	{ "", "Nowicjusz w Walce SMG", "Doswiadczony w Walce SMG", "Weteran w Walce SMG", "Mistrz w Walce SMG" },
	{ "", "Nowicjusz w Walce Czasowej", "Doswiadczony w Walce Czasowej", "Weteran w Walce Czasowej", "Mistrz w Walce Czasowej" },
	{ "", "Nowicjusz w Walce Ogolnej", "Doswiadczony w Walce Ogolnej", "Weteran w Walce Ogolnej", "Mistrz w Walce Ogolnej" }
};

new const bf1BadgeInfo[MAX_BADGES][] = {
	"Masz szanse na dostanie cichego chodzenia podczas odrodzenia",
	"Masz szanse na odbicie pocisku, ktory cie trafil",
	"Masz szanse na krytyczne trafienie (1 hit = dead)",
	"Dostajesz dodatkowe pieniadze podczas odrodzenia",
	"Dostajesz dodatkowe HP podczas odrodzenia",
	"Wszystkie bronie zadaja ci mniejsze obrazenia",
	"Zadajesz zwiekszone obrazenia z kazdej broni",
	"Masz zwiekszona predkosc poruszania sie",
	"Jestes niewidzialny na nozu",
	"Otrzymujesz dodatkowe granaty podczas odrodzenia"
};

new const invisibilityValues[] = {
	150,	//Nowicjusz
	110,	//Doswiadczony
	70,		//Weteran
	30,		//Mistrz
};

enum _:menuType { MENU_MAIN, MENU_HELP, MENU_STATS, MENU_TIME, MENU_BADGES, MENU_PLAYERBADGES, MENU_PLAYERSTATS };
enum _:hudType { TYPE_HUD, TYPE_DHUD, TYPE_STATUSTEXT };
enum _:saveType { NORMAL, DISCONNECT, MAP_END };

new cvarBf1Enabled, cvarBadgePowers, cvarMinPlayers, Float:cvarIconTime, cvarPackagesEnabled, cvarDropChance,
	cvarAssistEnabled, cvarAssistDamage, cvarBadgeHP, Float:cvarBadgeSpeed, cvarBadgeMoney, cvarBadgeArmor, cvarHelpUrl[64];

new playerDamage[MAX_PLAYERS + 1][MAX_PLAYERS + 1], loaded, newPlayer, visitInfo, invisible, round = 0;

new configPath[64], bool:blockPackages, bool:blockPowers, bool:freezeTime, bool:sqlConnected,
	bool:serverLoaded, Handle:sql, Handle:connection, Float:gameTime, msgStatusText, hudSync, hudSyncAim;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("bf1_version", VERSION, FCVAR_SERVER);

	create_cvar("bf1_sql_host", "127.0.0.1", FCVAR_SPONLY | FCVAR_PROTECTED);
	create_cvar("bf1_sql_user", "user", FCVAR_SPONLY | FCVAR_PROTECTED);
	create_cvar("bf1_sql_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED);
	create_cvar("bf1_sql_db", "database", FCVAR_SPONLY | FCVAR_PROTECTED);

	bind_pcvar_num(create_cvar("bf1_enabled", "1"), cvarBf1Enabled);
	bind_pcvar_num(create_cvar("bf1_badge_powers", "1"), cvarBadgePowers);
	bind_pcvar_num(create_cvar("bf1_min_players", "4"), cvarMinPlayers);
	bind_pcvar_float(create_cvar("bf1_icon_time", "1.5"), cvarIconTime);
	bind_pcvar_num(create_cvar("bf1_package_enabled", "1"), cvarPackagesEnabled);
	bind_pcvar_num(create_cvar("bf1_drop_chance", "8"), cvarDropChance);
	bind_pcvar_num(create_cvar("cod_assist_enabled", "1"), cvarAssistEnabled);
	bind_pcvar_num(create_cvar("cod_assist_damage", "65"), cvarAssistDamage);
	bind_pcvar_num(create_cvar("bf1_badge_hp", "5"), cvarBadgeHP);
	bind_pcvar_float(create_cvar("bf1_badge_speed", "10.0"), cvarBadgeSpeed);
	bind_pcvar_num(create_cvar("bf1_badge_money", "250"), cvarBadgeMoney);
	bind_pcvar_num(create_cvar("bf1_bonus_armor", "25"), cvarBadgeArmor);
	bind_pcvar_string(create_cvar("bf1_help_url", "http://bf1mod.5v.pl/bf1webdocs"), cvarHelpUrl, charsmax(cvarHelpUrl));

	for(new i; i < sizeof cmdMainMenu; i++) register_clcmd(cmdMainMenu[i], "menu_bf1");
	for(new i; i < sizeof cmdHelp; i++) register_clcmd(cmdHelp[i], "cmd_help");
	for(new i; i < sizeof cmdHelpMenu; i++) register_clcmd(cmdHelpMenu[i], "menu_help");
	for(new i; i < sizeof cmdBadges; i++) register_clcmd(cmdBadges[i], "menu_badges");
	for(new i; i < sizeof cmdOrders; i++) register_clcmd(cmdOrders[i], "cmd_orders");
	for(new i; i < sizeof cmdRanks; i++) register_clcmd(cmdRanks[i], "cmd_rank_help");
	for(new i; i < sizeof cmdPlayers; i++) register_clcmd(cmdPlayers[i], "cmd_ranks");
	for(new i; i < sizeof cmdStats; i++) register_clcmd(cmdStats[i], "cmd_my_stats");
	for(new i; i < sizeof cmdStatsMenu; i++) register_clcmd(cmdStatsMenu[i], "menu_stats");
	for(new i; i < sizeof cmdStatsServer; i++) register_clcmd(cmdStatsServer[i], "cmd_server_stats");
	for(new i; i < sizeof cmdHud; i++) register_clcmd(cmdHud[i], "menu_hud");
	for(new i; i < sizeof cmdTime; i++) register_clcmd(cmdTime[i], "cmd_time");
	for(new i; i < sizeof cmdTimeMenu; i++) register_clcmd(cmdTimeMenu[i], "menu_time");
	for(new i; i < sizeof cmdTimeTop; i++) register_clcmd(cmdTimeTop[i], "cmd_time_top");
	for(new i; i < sizeof cmdDegrees; i++) register_clcmd(cmdDegrees[i], "cmd_degrees");

	register_clcmd("say", "cmd_say");
	register_clcmd("say_team", "cmd_say");

	register_concmd("bf1_addbadge", "cmd_add_badge", ADMIN_ALL, "<player> <badge> <level>");
	register_concmd("bf1_addbadgesql", "cmd_add_badge_sql", ADMIN_ALL, "<player> <badge> <level>");

	register_clcmd("flash", "flashbang_buy");
	register_clcmd("hegren", "hegrenade_buy");
	register_clcmd("sgren", "smokegrenade_buy");

	register_menucmd(-34, (1<<2), "flashbang_buy");
	register_menucmd(-34, (1<<3), "hegrenade_buy");
	register_menucmd(-34, (1<<4), "smokegrenade_buy");

	register_menucmd(register_menuid("BuyItem"), (1<<2), "flashbang_buy");
	register_menucmd(register_menuid("BuyItem"), (1<<3), "hegrenade_buy");
	register_menucmd(register_menuid("BuyItem"), (1<<4), "smokegrenade_buy");

	register_event("DeathMsg", "event_deathmsg", "a");
	register_event("TextMsg", "event_game_commencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_event("TextMsg", "event_hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("StatusValue", "event_on_showstatus", "be", "1=2", "2!0");
	register_event("StatusValue", "event_on_hidestatus", "be", "1=1", "2=0");
	register_event("Money", "event_money", "be");

	register_logevent("event_round_start", 2, "0=World triggered", "1=Round_Start");
	register_logevent("event_round_end", 2, "1=Round_End");

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
	RegisterHam(Ham_TakeDamage, "player", "player_take_damage", 0);
	RegisterHam(Ham_Touch, "armoury_entity", "touch_grenades", 0);
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "set_speed", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "weapon_knife", 1);
	for (new i = 0; i < sizeof weaponNames; i++) RegisterHam(Ham_Item_Deploy, weaponNames[i], "weapon_other", 1);

	register_forward(FM_PlayerPreThink, "player_prethink");
	register_forward(FM_Touch, "touch_package");

	register_message(SVC_INTERMISSION, "award_check");
	register_message(get_user_msgid("SayText"), "chat_prefix");
	register_message(get_user_msgid("TextMsg") , "block_message");

	hudSync = CreateHudSyncObj();
	hudSyncAim = CreateHudSyncObj();

	msgStatusText = get_user_msgid("StatusText");

	set_task(180.0, "display_help", TASK_HELP, .flags = "b");
}

public plugin_natives()
{
	register_library("bf1");

	register_native("bf1_get_maxbadges","_bf1_get_maxbadges");
	register_native("bf1_get_badge_name","_bf1_get_badge_name", 1);
	register_native("bf1_get_user_badge", "_bf1_get_user_badge");
	register_native("bf1_set_user_badge", "_bf1_set_user_badge");
}

public plugin_precache()
{
	new bool:error, precacheFile[32];

	for (new i = 0; i < sizeof(bf1Resources); i++) {
		if (!file_exists(bf1Resources[i])) {
			log_to_file(LOG_FILE, "[ERROR] Brakujacy plik: ^"%s^"", bf1Resources[i]);

			error = true;
		} else bf1Resource[i] = precache_model(bf1Resources[i]);
	}

	for (new i = 0; i < sizeof(bf1Sounds); i++) {
		formatex(precacheFile, charsmax(precacheFile), "sound/%s", bf1Sounds[i]);

		if (!file_exists(precacheFile)) {
			log_to_file(LOG_FILE, "[ERROR] Brakujacy plik: ^"%s^"", precacheFile);

			error = true;
		} else precache_sound(bf1Sounds[i]);
	}

	for (new i = 0; i < MAX_RANKS + MAX_BONUSRANKS; i++) {
		formatex(precacheFile, charsmax(precacheFile), "sprites/bf1/%d.spr", i);

		if (!file_exists(precacheFile)) {
			log_to_file(LOG_FILE, "[ERROR] Brakujacy plik: ^"%s^"", precacheFile);

			error = true;
		} else sprites[i] = precache_model(precacheFile);
	}

	if (error) set_fail_state("[BF1] Zaladowanie pluginu niemozliwe - brak wymaganych plikow! Sprawdz logi w BF1.log!");
}

public plugin_cfg()
{
	new configPath[64];

	get_localinfo("amxx_configsdir", configPath, charsmax(configPath));

	server_cmd("exec %s/bf1_mod.cfg", configPath);
	server_exec();

	server_cmd("sv_maxspeed 500");

	sql_init();
	check_map();

	log_amx("Battlefield One Mod by O'Zone (v%s).", VERSION);
}

public plugin_end()
{
	save_server();

	if (sql != Empty_Handle) SQL_FreeHandle(sql);
	if (connection != Empty_Handle) SQL_FreeHandle(connection);
}

public client_connect(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return PLUGIN_CONTINUE;

	for(new i = 0; i <= ORDERS_COUNT; i++) bf1Player[id][i] = 0;
	for(new i = 0; i < MAX_BADGES; i++) bf1Player[id][BADGES][i] = 0;
	for(new i = 0; i < MAX_ORDERS; i++) bf1Player[id][ORDERS][i] = 0;

	bf1Player[id][HUD] = TYPE_HUD;
	bf1Player[id][HUD_RED] = 255;
	bf1Player[id][HUD_GREEN] = 128;
	bf1Player[id][HUD_BLUE] = 0;
	bf1Player[id][HUD_POSX] = 66;
	bf1Player[id][HUD_POSY] = 6;

	set_bit(id, newPlayer);
	set_bit(id, visitInfo);

	rem_bit(id, loaded);
	rem_bit(id, invisible);

	remove_task(id + TASK_HUD);
	remove_task(id + TASK_AD);

	get_user_name(id, bf1Player[id][NAME], charsmax(bf1Player[]));

	mysql_escape_string(bf1Player[id][NAME], bf1Player[id][SAFE_NAME], charsmax(bf1Player[]));

	load_stats(id);

	cmd_execute(id, "hud_centerid 0");
	cmd_execute(id, "cl_shadows 0");

	set_task(0.1, "display_hud", id + TASK_HUD, _, _, "b");
	set_task(30.0, "display_advertisement", id + TASK_AD);

	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	save_stats(id, DISCONNECT);

	if (bf1Player[id][KILLS] == bf1Server[MOSTSERVERKILLS]) bf1Server[MOSTSERVERKILLSID] = 0;

	if (id == bf1Server[MOSTKILLSID]) most_kills_disconnect();
	if (id == bf1Server[MOSTWINSID]) most_wins_disconnect();
	if (id == bf1Server[HIGHESTRANKID]) highest_rank_disconnect();
}

public client_death(killer, victim, weapon, hitPlace, teamKill)
{
	if (!cvarBf1Enabled || !is_user_connected(killer)) return;

	if (killer == victim) {
		check_badges(victim);

		return;
	}

	switch (weapon) {
		case CSW_KNIFE: bf1Player[killer][KNIFE]++;
		case CSW_M249: bf1Player[killer][M249]++;
		case CSW_AWP: { bf1Player[killer][SNIPER]++; bf1Player[killer][AWP]++; }
		case CSW_SCOUT: { bf1Player[killer][SNIPER]++; bf1Player[killer][SCOUT]++; }
		case CSW_G3SG1: { bf1Player[killer][SNIPER]++; bf1Player[killer][G3SG1]++; }
		case CSW_SG550: { bf1Player[killer][SNIPER]++; bf1Player[killer][SG550]++; }
		case CSW_DEAGLE: { bf1Player[killer][PISTOL]++; bf1Player[killer][DEAGLE]++; }
		case CSW_ELITE: { bf1Player[killer][PISTOL]++; bf1Player[killer][ELITES]++; }
		case CSW_USP: { bf1Player[killer][PISTOL]++; bf1Player[killer][USP]++; }
		case CSW_FIVESEVEN: { bf1Player[killer][PISTOL]++; bf1Player[killer][FIVESEVEN]++; }
		case CSW_P228: { bf1Player[killer][PISTOL]++; bf1Player[killer][P228]++; }
		case CSW_GLOCK18: { bf1Player[killer][PISTOL]++; bf1Player[killer][GLOCK]++; }
		case CSW_XM1014: { bf1Player[killer][XM1014]++; bf1Player[killer][SHOTGUN]++; }
		case CSW_M3: { bf1Player[killer][M3]++; bf1Player[killer][SHOTGUN]++; }
		case CSW_MAC10: { bf1Player[killer][MAC10]++; bf1Player[killer][SMG]++; }
		case CSW_UMP45: { bf1Player[killer][UMP45]++; bf1Player[killer][SMG]++; }
		case CSW_MP5NAVY: { bf1Player[killer][MP5]++; bf1Player[killer][SMG]++; }
		case CSW_TMP: { bf1Player[killer][TMP]++; bf1Player[killer][SMG]++; }
		case CSW_P90: { bf1Player[killer][P90]++; bf1Player[killer][SMG]++; }
		case CSW_AUG: { bf1Player[killer][AUG]++; bf1Player[killer][RIFLE]++; }
		case CSW_GALIL: { bf1Player[killer][GALIL]++; bf1Player[killer][RIFLE]++; }
		case CSW_FAMAS: { bf1Player[killer][FAMAS]++; bf1Player[killer][RIFLE]++; }
		case CSW_M4A1: { bf1Player[killer][M4A1]++; bf1Player[killer][RIFLE]++; }
		case CSW_AK47: { bf1Player[killer][AK47]++; bf1Player[killer][RIFLE]++; }
		case CSW_SG552: { bf1Player[killer][SG552]++; bf1Player[killer][RIFLE]++; }
		case CSW_HEGRENADE: bf1Player[killer][GRENADE]++;
	}

	if (cvarAssistEnabled) {
		new assist = 0, damage = 0;

		for (new id = 1; id <= MAX_PLAYERS; id++) {
			if (!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || id == killer) continue;

			if (playerDamage[id][victim] > damage) {
				assist = id;
				damage = playerDamage[id][victim];
			}

			playerDamage[id][victim] = 0;
		}

		if (assist > 0 && damage > cvarAssistDamage) {
			set_user_frags(assist, get_user_frags(assist) + 1);

			cs_set_user_deaths(assist, cs_get_user_deaths(assist));

			new nameVictim[MAX_NAME], nameKiller[MAX_NAME];

			get_user_name(victim, nameVictim, charsmax(nameVictim));
			get_user_name(killer, nameKiller, charsmax(nameKiller));

			client_print_color(assist, assist, "^x04[BF1]^x03 %s^x01 w zabiciu^x03 %s^x01. Dostajesz fraga!", nameKiller, nameVictim);

			switch (weapon) {
				case CSW_KNIFE: bf1Player[assist][KNIFE]++;
				case CSW_M249: bf1Player[assist][M249]++;
				case CSW_AWP: { bf1Player[assist][SNIPER]++; bf1Player[assist][AWP]++; }
				case CSW_SCOUT: { bf1Player[assist][SNIPER]++; bf1Player[assist][SCOUT]++; }
				case CSW_G3SG1: { bf1Player[assist][SNIPER]++; bf1Player[assist][G3SG1]++; }
				case CSW_SG550: { bf1Player[assist][SNIPER]++; bf1Player[assist][SG550]++; }
				case CSW_DEAGLE: { bf1Player[assist][PISTOL]++; bf1Player[assist][DEAGLE]++; }
				case CSW_ELITE: { bf1Player[assist][PISTOL]++; bf1Player[assist][ELITES]++; }
				case CSW_USP: { bf1Player[assist][PISTOL]++; bf1Player[assist][USP]++; }
				case CSW_FIVESEVEN: { bf1Player[assist][PISTOL]++; bf1Player[assist][FIVESEVEN]++; }
				case CSW_P228: { bf1Player[assist][PISTOL]++; bf1Player[assist][P228]++; }
				case CSW_GLOCK18: { bf1Player[assist][PISTOL]++; bf1Player[assist][GLOCK]++; }
				case CSW_XM1014: { bf1Player[assist][XM1014]++; bf1Player[assist][SHOTGUN]++; }
				case CSW_M3: { bf1Player[assist][M3]++; bf1Player[assist][SHOTGUN]++; }
				case CSW_MAC10: { bf1Player[assist][MAC10]++; bf1Player[assist][SMG]++; }
				case CSW_UMP45: { bf1Player[assist][UMP45]++; bf1Player[assist][SMG]++; }
				case CSW_MP5NAVY: { bf1Player[assist][MP5]++; bf1Player[assist][SMG]++; }
				case CSW_TMP: { bf1Player[assist][TMP]++; bf1Player[assist][SMG]++; }
				case CSW_P90: { bf1Player[assist][P90]++; bf1Player[assist][SMG]++; }
				case CSW_AUG: { bf1Player[assist][AUG]++; bf1Player[assist][RIFLE]++; }
				case CSW_GALIL: { bf1Player[assist][GALIL]++; bf1Player[assist][RIFLE]++; }
				case CSW_FAMAS: { bf1Player[assist][FAMAS]++; bf1Player[assist][RIFLE]++; }
				case CSW_M4A1: { bf1Player[assist][M4A1]++; bf1Player[assist][RIFLE]++; }
				case CSW_AK47: { bf1Player[assist][AK47]++; bf1Player[assist][RIFLE]++; }
				case CSW_SG552: { bf1Player[assist][SG552]++; bf1Player[assist][RIFLE]++; }
				case CSW_HEGRENADE: bf1Player[assist][GRENADE]++;
			}

			bf1Player[assist][ASSISTS]++;
			bf1Player[assist][KILLS]++;
		}
	}

	if (hitPlace == HIT_HEAD) bf1Player[killer][HS_KILLS]++;

	bf1Player[killer][KILLS]++;

	check_badges(victim);

	if (bf1Server[MOSTKILLSID] == killer) {
		bf1Server[MOSTKILLS]++;
	} else if (bf1Player[killer][KILLS] > bf1Server[MOSTKILLS]) {
		bf1Server[MOSTKILLS] = bf1Player[killer][KILLS];
		bf1Server[MOSTKILLSID] = killer;

		get_user_name(killer, bf1Server[MOSTKILLSNAME], charsmax(bf1Server[MOSTKILLSNAME]));

		client_print_color(killer, killer, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem we fragach z^x03 %i^x01 zabiciami.", bf1Server[MOSTKILLSNAME], bf1Server[MOSTKILLS]);
	}

	if (bf1Server[MOSTSERVERKILLSID] == killer) {
		bf1Server[MOSTSERVERKILLS]++;
	} else if (bf1Player[killer][KILLS] > bf1Server[MOSTSERVERKILLS]) {
		bf1Server[MOSTSERVERKILLS] = bf1Player[killer][KILLS];

		client_cmd(killer, "spk %s", bf1Sounds[SOUND_RANKUP]);

		get_user_name(killer, bf1Server[MOSTSERVERKILLSNAME], charsmax(bf1Server[MOSTSERVERKILLSNAME]));

		client_print_color(killer, killer, "^x04[BF1]^x01 Gratulacje dla^x03 %s^x01 nowego^x03 ogolnego^x01 lidera we fragach z^x03 %i^x01 zabiciami.", bf1Server[MOSTSERVERKILLSNAME], bf1Server[MOSTSERVERKILLS]);
	}
}

public bomb_planted(planter)
{
	if (get_playersnum() < cvarMinPlayers) return;

	bf1Player[planter][PLANTS]++;
}

public bomb_explode(planter, defuser)
{
	if (get_playersnum() < cvarMinPlayers) return;

	bf1Player[planter][EXPLOSIONS]++;
	bf1Player[planter][KILLS] += 3;

	client_print_color(planter, planter, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za wybuch bomby.");
}

public bomb_defused(defuser)
{
	if (get_playersnum() < cvarMinPlayers) return;

	bf1Player[defuser][DEFUSES]++;
	bf1Player[defuser][KILLS] += 3;

	client_print_color(defuser, defuser, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za rozbrojenie bomby.");
}

public event_hostages_rescued()
{
	if (get_playersnum() < cvarMinPlayers) return;

	new logUser[80], playerName[MAX_NAME];

	read_logargv(0, logUser, charsmax(logUser));
	parse_loguser(logUser, playerName, charsmax(playerName));

	new rescuer = get_user_index(playerName);

	bf1Player[rescuer][RESCUES]++;
	bf1Player[rescuer][KILLS] += 3;

	client_print_color(rescuer, rescuer, "^x04[BF1]^x01 Dostales^x03 3 fragi^x01 do rangi za uratowanie zakladnikow.");
}

public event_deathmsg()
{
	new killer = read_data(1), victim = read_data(2);

	if (!is_user_alive(killer) || !is_user_connected(victim)) return;

	check_badges(victim);

	if (killer == victim || !cvarPackagesEnabled || blockPackages) return;

	if (random_num(1, cvarDropChance) == 1) {
		new playerName[MAX_LENGTH];

		get_user_name(victim, playerName, charsmax(playerName));

		place_package(victim);

		client_print_color(killer, killer, "^x04[BF1]^x01 Zabiles^x03 %s^x01 i wypadla z niego^x03 paczka^x01. Zabierz ja szybko, bo mozesz znalezc w niej kase, fragi, a nawet odznake!", playerName);
	}
}

public event_on_hidestatus(id)
	ClearSyncHud(id, hudSyncAim);

public event_on_showstatus(id)
{
	new playerName[MAX_LENGTH], player = read_data(2), playerRank = bf1Player[player][RANK], firstColor = 0, secondColor = 0;

	get_user_name(player, playerName, charsmax(playerName));

	if (get_user_team(player) == 1) firstColor = 255;
	else secondColor = 255;

	if (get_user_team(player) == get_user_team(id)) {
		new weaponName[32], weapon = get_user_weapon(player);

		if (weapon) xmod_get_wpnname(weapon, weaponName, charsmax(weaponName));

		set_hudmessage(firstColor, 50, secondColor, -1.0, 0.35, 1, 0.01, 3.0, 0.01, 0.01);

		ShowSyncHudMsg(id, hudSyncAim, "%s : %s^n%d HP / %d AP / %s", playerName, bf1RankName[playerRank], get_user_health(player), get_user_armor(player), weaponName);

		new iconTime = floatround(cvarIconTime * 10);

		if (iconTime > 0) create_icon(id, player, 55, sprites[playerRank], iconTime);
	} else if (!get_bit(player, invisible)) {
		set_hudmessage(firstColor, 50, secondColor, -1.0, 0.35, 1, 0.01, 3.0, 0.01, 0.01);

		ShowSyncHudMsg(id, hudSyncAim, "%s : %s", playerName, bf1RankName[playerRank]);
	}
}

public event_round_end()
{
	new players[MAX_PLAYERS], playersNum;

	get_players(players, playersNum, "ah");

	for (new i = 0; i < playersNum; i++) {
		check_badges(players[i]);

		bf1Player[players[i]][SURVIVED]++;
	}
}

public event_round_start()
	freezeTime = false;

public event_new_round()
{
	gameTime = get_gametime();

	freezeTime = true;

	round++;

	new ent = -1;

	while((ent = find_ent_by_class(ent, "package")) != 0) {
		engfunc(EngFunc_RemoveEntity, ent);
	}

	ent = -1;

	while ((ent = find_ent_by_class(ent, "armoury_entity")) != 0) {
		set_entity_visibility(ent, 1);

		entity_set_int(ent, EV_INT_iuser1, 0);
	}
}

public event_game_commencing()
	round = 0;

public event_money(id)
{
	new money = read_data(1);

	if (money > bf1Player[id][MONEY]) bf1Player[id][EARNED] += (money - bf1Player[id][MONEY]);

	bf1Player[id][MONEY] = money;
}

public weapon_knife(ent)
{
	if (pev_valid(ent) != 2) return HAM_IGNORED;

	static id; id = get_pdata_cbase(ent, 41, 4);

	if (!is_user_alive(id)) return HAM_IGNORED;

	set_render(id, false);

	return HAM_IGNORED;
}

public weapon_other(ent)
{
	if (pev_valid(ent) != 2) return HAM_IGNORED;

	static id; id = get_pdata_cbase(ent, 41, 4);

	if (!is_user_alive(id)) return HAM_IGNORED;

	reset_render(id);

	return HAM_IGNORED;
}

stock set_render(id, check=true)
{
	if (!cvarBadgePowers || blockPowers || !is_user_alive(id) || (check && get_user_weapon(id) != CSW_KNIFE)) return;

	new timeBadgeLevel = bf1Player[id][BADGES][BADGE_TIME];

	if (timeBadgeLevel) {
		fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, invisibilityValues[timeBadgeLevel - 1]);

		set_bit(id, invisible);
	}
}

public reset_render(id)
{
	if (!cvarBadgePowers || blockPowers || !is_user_alive(id)) return;

	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 255);

	rem_bit(id, invisible);
}

public give_weapons(id)
{
	if (!cvarBadgePowers || blockPowers || !is_user_alive(id)) return;

	new bool:bonus;

	new sniperBadgeLevel = bf1Player[id][BADGES][BADGE_SNIPER];

	if (sniperBadgeLevel && round >= 2) {
		if (random_num(1, 5 - sniperBadgeLevel) == 1) {
			if (check_weapons(id)) {
				client_print_color(id, id, "^x04[BF1]^x01 Nie otrzymales Scouta z racji posiadania odznaki za Walke Bronia Snajperska, bo masz juz bron!");
			} else {
				fm_give_item(id, "weapon_scout");

				cs_set_user_bpammo(id, CSW_SCOUT, 90);

				bonus = true;
			}
		}

		cs_set_user_money(id, min(cs_get_user_money(id) + cvarBadgeMoney * sniperBadgeLevel, 16000), 1);

		bonus = true;
	}

	new knifeBadgeLevel = bf1Player[id][BADGES][BADGE_KNIFE];

	if (knifeBadgeLevel && random_num(1, 5 - knifeBadgeLevel) == 1) {
		set_user_footsteps(id, 1);

		bonus = true;
	} else set_user_footsteps(id, 0);

	new supportBadgeLevel = bf1Player[id][BADGES][BADGE_SUPPORT];

	if (supportBadgeLevel) {
		new hp = 100 + (supportBadgeLevel * cvarBadgeHP);

		set_user_health(id, hp);
		set_pev(id, pev_max_health, float(hp));

		bonus = true;
	}

	new generalBadgeLevel = bf1Player[id][BADGES][BADGE_GENERAL];

	if (generalBadgeLevel) {
		handle_buy(id, CSW_FLASHBANG, 1);

		if (generalBadgeLevel > LEVEL_START) handle_buy(id, CSW_HEGRENADE, 1);
		if (generalBadgeLevel > LEVEL_EXPERIENCED) handle_buy(id, CSW_FLASHBANG, 1);
		if (generalBadgeLevel > LEVEL_VETERAN) handle_buy(id, CSW_SMOKEGRENADE, 1);
	}

	new CsArmorType:armorType, armor, playerArmor = cs_get_user_armor(id, armorType);

	switch (bf1Player[id][BADGES_COUNT]) {
		case 10 .. 19: armor = cvarBadgeArmor;
		case 20 .. 29: armor = cvarBadgeArmor * 2;
		case 30 .. 39: armor = cvarBadgeArmor * 3;
		case 40: armor = cvarBadgeArmor * 4;
	}

	if (playerArmor < armor) {
		cs_set_user_armor(id, armor, CS_ARMOR_VESTHELM);

		bonus = true;
	}

	if (bonus) screen_flash(id, 0, 255, 0, 100);
}

public player_spawn(id)
{
	if (!cvarBf1Enabled || !is_user_alive(id)) return HAM_IGNORED;

	for (new i = 1; i <= MAX_PLAYERS; i++) playerDamage[id][i] = 0;

	check_rank(id);

	if (!cvarBadgePowers || blockPowers) return HAM_IGNORED;

	set_render(id);

	set_task(0.1, "give_weapons", id);

	if (get_bit(id, visitInfo)) set_task(3.0, "check_time", id + TASK_TIME);

	if (get_bit(id, newPlayer) && get_bit(id, loaded)) {
		rem_bit(id, newPlayer);

		client_cmd(id, "spk %s", bf1Sounds[SOUND_LOAD]);

		client_print_color(id, id, "^x04[BF1]^x01 Twoja ranga^x03 %s^x01 zostala zaladowana.", bf1RankName[bf1Player[id][RANK]]);
	}

	return HAM_IGNORED;
}

public player_take_damage(victim, inflictor, attacker, Float:damage, damageBits)
{
	if (!cvarBadgePowers || blockPowers || !is_user_connected(attacker) || !is_user_alive(victim)) return HAM_IGNORED;

	if (victim == attacker || cs_get_user_team(victim) == cs_get_user_team(attacker)) return HAM_IGNORED;

	if (damageBits & DMG_BULLET) {
		new bool:critical;

		switch (bf1Player[attacker][BADGES][BADGE_ASSAULT]) {
			case LEVEL_START: if (random_num(1, 100) == 1) critical = true;
			case LEVEL_EXPERIENCED: if (random_num(1, 65) == 1) critical = true;
			case LEVEL_VETERAN: if (random_num(1, 50) == 1) critical = true;
			case LEVEL_MASTER: if (random_num(1, 40) == 1) critical = true;
		}

		if (critical) {
			cs_set_user_armor(victim, 0, CS_ARMOR_NONE);

			SetHamParamFloat(4, float(get_user_health(victim) + 1));

			return HAM_HANDLED;
		}
	}

	new shotgunBadgeLevel = bf1Player[attacker][BADGES][BADGE_SHOTGUN],
		explosivesBadgeLevel = bf1Player[victim][BADGES][BADGE_EXPLOSIVES],
		pistolBadgeLevel = bf1Player[victim][BADGES][BADGE_PISTOL];

	if (shotgunBadgeLevel) damage += damage * shotgunBadgeLevel * 0.04;

	if (explosivesBadgeLevel) damage -= damage * explosivesBadgeLevel * 0.04;

	if (pistolBadgeLevel && random_num(1, 16 - pistolBadgeLevel * 2) == 1 && damageBits & DMG_BULLET) {
		ExecuteHam(Ham_TakeDamage, attacker, victim, victim, damage, damageBits);

		player_glow(victim, 255, 0, 0);

		return HAM_SUPERCEDE;
	}

	SetHamParamFloat(4, damage);

	bf1Player[victim][DMG_RECEIVED] += floatround(damage);
	bf1Player[attacker][DMG_TAKEN] += floatround(damage);
	playerDamage[attacker][victim] += floatround(damage);

	return HAM_HANDLED;
}

public set_speed(id)
{
	if (freezeTime || !is_user_alive(id)) return HAM_IGNORED;

	set_user_maxspeed(id, get_user_maxspeed(id) + bf1Player[id][BADGES][BADGE_SMG] * cvarBadgeSpeed);

	return HAM_IGNORED;
}

public player_prethink(id)
{
	if (is_user_alive(id)) {
		new Float:vector[3];

		pev(id, pev_velocity, vector);

		new Float:speed = floatsqroot(vector[0] * vector[0] + vector[1] * vector[1] + vector[2] * vector[2]);

		if ((fm_get_user_maxspeed(id) * 5) > (speed * 9)) set_pev(id, pev_flTimeStepSound, 300);
	}
}

public use_package(id)
{
	if (!is_user_connected(id) || !is_user_alive(id) || !cvarPackagesEnabled || blockPackages) return PLUGIN_HANDLED;

	switch (random_num(1, 15)) {
		case 1 .. 3: {
			new randomHP = random_num(5, 25), maxHP = 100 + (bf1Player[id][BADGES][BADGE_ASSAULT] * cvarBadgeHP);

			fm_set_user_health(id, min(get_user_health(id) + randomHP, maxHP));

			client_print_color(id, id, "^x04[BF1]^x01 Znalazles mala apteczke. Dostajesz^x03 %i^x01 HP!", randomHP);
		} case 4 .. 6: {
			new randomHP = random_num(25, 50), maxHP = 100 + (bf1Player[id][BADGES][BADGE_ASSAULT] * cvarBadgeHP);

			fm_set_user_health(id, min(get_user_health(id) + randomHP, maxHP));

			client_print_color(id, id, "^x04[BF1]^x01 Znalazles duza apteczke. Dostajesz^x03 %i^x01 HP!", randomHP);
		} case 7 .. 9: {
			new randomMoney = random_num(500, 2500);

			cs_set_user_money(id, min(cs_get_user_money(id) + randomMoney, 16000), 1);

			client_print_color(id, id, "^x04[BF1]^x01 Znalazles troche gotowki. Dostajesz^x03 %i$^x01!", randomMoney);
		} case 10 .. 12: {
			new randomMoney = random_num(2500, 6000);

			cs_set_user_money(id, min(cs_get_user_money(id) + randomMoney, 16000), 1);

			client_print_color(id, id, "^x04[BF1]^x01 Znalazles sporo gotowki. Dostajesz^x03 %i$^x01!", randomMoney);
		} case 13, 14: {
			set_user_frags(id, get_user_frags(id) + 1);

			bf1Player[id][KILLS]++;

			client_print_color(id, id, "^x04[BF1]^x01 Niezle! Dostajesz dodatkowego^x03 fraga^x01.");
		} case 15: {
			new Array:allBadges = ArrayCreate(1, MAX_BADGES), badges;

			for (new i = 0; i < MAX_BADGES; i++) {
				if (bf1Player[id][BADGES][i] >= LEVEL_START) badges++;

				ArrayPushCell(allBadges, i);
			}

			if (badges < MAX_BADGES) {
				for (new j = 0; j < MAX_BADGES; j++) {
					new randomBadge = random_num(0, MAX_BADGES - 1 - j), badge = ArrayGetCell(allBadges, randomBadge);

					if (bf1Player[id][BADGES][badge] < LEVEL_START) {
						bf1Player[id][BADGES][badge] = LEVEL_START;

						client_print_color(id, id, "^x04[BF1]^x01 Wow! Znalazles losowa^x03 odznake^x01 na poziomie^x03 Nowicjusz^x01.");

						break;
					}

					ArrayDeleteItem(allBadges, randomBadge);
				}
			} else {
				set_user_frags(id, get_user_frags(id) + 2);

				bf1Player[id][KILLS] += 2;

				client_print_color(id, id, "^x04[BF1]^x01 Masz wszystkie odznaki z poziomu Nowicjusz, wiec dostajesz^x03 dwa fragi^x01.");
			}

			ArrayDestroy(Array:allBadges);
		}
	}

	return PLUGIN_HANDLED;
}

public place_package(id)
{
	new ent, Float:origin[3];

	entity_get_vector(id, EV_VEC_origin, origin);

	origin[0] += 30.0;
	origin[2] -= distance_to_floor(origin);

	ent = fm_create_entity("info_target");

	set_pev(ent, pev_classname, "bf1_package");

	engfunc(EngFunc_SetModel, ent, bf1Resources[MODEL_PACKAGE]);

	entity_set_origin(ent, origin);

	set_pev(ent, pev_mins, Float:{ -10.0, -10.0, 0.0 });
	set_pev(ent, pev_maxs, Float:{ 10.0, 10.0, 50.0 });
	set_pev(ent, pev_size, Float:{ -1.0, -3.0, 0.0, 1.0, 1.0, 10.0 });
	engfunc(EngFunc_SetSize, ent, Float:{ -1.0, -3.0, 0.0 }, Float:{ 1.0, 1.0, 10.0 });

	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);
	set_pev(ent, pev_movetype, MOVETYPE_FLY);

	return PLUGIN_CONTINUE;
}

public touch_package(entity, id)
{
	if (!pev_valid(entity) || !is_user_alive(id)) return FMRES_IGNORED;

	static className[64];

	pev(entity, pev_classname, className, charsmax(className));

	if (!equal(className, "bf1_package")) return FMRES_IGNORED;

	new origin[3];

	get_user_origin(id, origin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(bf1Resource[SPRITE_GREEN]);
	write_byte(20);
	write_byte(255);
	message_end();

	message_begin(MSG_ALL, SVC_TEMPENTITY, {0, 0, 0}, id);
	write_byte(TE_SPRITETRAIL);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 20);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 80);
	write_short(bf1Resource[SPRITE_ACID]);
	write_byte(20);
	write_byte(20);
	write_byte(4);
	write_byte(20);
	write_byte(10);
	message_end();

	engfunc(EngFunc_RemoveEntity, entity);
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, bf1Sounds[SOUND_PACKAGE], 1.0, ATTN_NORM, 0, PITCH_NORM);

	use_package(id);

	return FMRES_IGNORED;
}

public check_rank(id)
{
	if (!get_bit(id, loaded)) return;

	new stats[8], hits[8], previousRank = bf1Player[id][RANK], rank = get_user_stats(id, stats, hits);

	bf1Player[id][RANK] = 0;

	while (bf1Player[id][RANK] < MAX_RANKS - 1 && bf1Player[id][KILLS] >= bf1RankKills[bf1Player[id][RANK] + 1]) {
		bf1Player[id][RANK]++;
	}

	bf1Player[id][NEXT_RANK] = (bf1Player[id][RANK] == MAX_RANKS - 1 ? bf1RankKills[bf1Player[id][RANK]] : bf1RankKills[bf1Player[id][RANK] + 1]);

	bf1Player[id][BADGES_COUNT] = 0;

	for (new i = 0; i < MAX_BADGES; i++) bf1Player[id][BADGES_COUNT] += bf1Player[id][BADGES][i];

	bf1Player[id][ORDERS_COUNT] = 0;

	for (new i = 0; i < MAX_ORDERS; i++) bf1Player[id][ORDERS_COUNT] += bf1Player[id][ORDERS][i];

	switch(bf1Player[id][RANK]) {
		case 9: if (bf1Player[id][BADGES_COUNT] >= MAX_BADGES) bf1Player[id][RANK] = 17;
		case 12: if (bf1Player[id][BADGES_COUNT] >= floatround(MAX_BADGES * 2.5)) bf1Player[id][RANK] = 18;
		case 15: if (bf1Player[id][BADGES_COUNT] == MAX_BADGES * 3) bf1Player[id][RANK] = 19;
		case 16: {
			if (bf1Player[id][BADGES_COUNT] == MAX_BADGES * 4) {
				switch (rank) {
					case 1: bf1Player[id][RANK] = 23;
					case 2: bf1Player[id][RANK] = 22;
					case 3: bf1Player[id][RANK] = 21;
					case 4 .. 15: bf1Player[id][RANK] = 20;
				}
			}
		}
	}

	if (bf1Player[id][KILLS] == bf1Server[MOSTSERVERKILLS]) bf1Server[MOSTSERVERKILLSID] = id;

	if (bf1Player[id][GOLD] > bf1Server[MOSTWINS]) {
		bf1Server[MOSTWINS] = bf1Player[id][RANK];
		bf1Server[MOSTWINSID] = id;

		get_user_name(id, bf1Server[MOSTWINSNAME], charsmax(bf1Server[MOSTWINSNAME]));
	}

	if (is_ranked_higher(bf1Player[id][RANK], previousRank)) {
		client_cmd(id, "spk %s", bf1Sounds[SOUND_RANKUP]);

		client_print_color(id, id, "^x04[BF1]^x01 Gratulacje! Awansowales do rangi^x03 %s^x01.", bf1RankName[bf1Player[id][RANK]]);
	}

	if (is_ranked_higher(bf1Player[id][RANK], bf1Server[HIGHESTRANK])) {
		bf1Server[HIGHESTRANK] = bf1Player[id][RANK];
		bf1Server[HIGHESTRANKID] = id;

		get_user_name(id, bf1Server[HIGHESTRANKNAME], charsmax(bf1Server[HIGHESTRANKNAME]));

		client_print_color(0, id, "^x04[BF1]^x03 %s^x01 jest aktualnie liderem Rankingu Oficerskiego z ranga^x03 %s^x01!", bf1Server[HIGHESTRANKNAME], bf1RankName[bf1Server[HIGHESTRANK]]);
	}

	if (is_ranked_higher(bf1Player[id][RANK], bf1Server[HIGHESTSERVERRANK])) {
		bf1Server[HIGHESTSERVERRANK] = bf1Player[id][RANK];

		client_cmd(id, "spk %s", bf1Sounds[SOUND_RANKUP]);

		get_user_name(id, bf1Server[HIGHESTSERVERRANKNAME], charsmax(bf1Server[HIGHESTSERVERRANKNAME]));

		client_print_color(0, id, "^x04[BF1]^x01 Gratulacje dla^x03 %s^x01 nowego^x03 ogolnego^x01 lidera Rankingu Oficerskiego z ranga^x03 %s^x01!", bf1Server[HIGHESTSERVERRANKNAME], bf1RankName[bf1Server[HIGHESTSERVERRANK]]);
	}
}

public check_badges(id)
{
	if (!cvarBf1Enabled) return;

	new weaponKills, roundKills, roundHSKills, badge, level, bool:gained;

	client_print_color(id, id, "^x04[BF1]^x01 Sprawdzanie zdobytych odznak i orderow...");

	badge = bf1Player[id][BADGES][BADGE_KNIFE];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		roundKills = 0;
		roundHSKills = 0;

		get_weapon_round_stats(id, CSW_KNIFE, roundKills, roundHSKills);

		weaponKills = bf1Player[id][KNIFE];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 50) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 100) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 250 && roundKills >= 2) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 500 && roundKills >= 3) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_KNIFE] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_KNIFE][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_PISTOL];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		roundKills = 0;
		roundHSKills = 0;

		get_weapon_round_stats(id, CSW_GLOCK18, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_USP, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_P228, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_DEAGLE, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_FIVESEVEN, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_ELITE, roundKills, roundHSKills);

		weaponKills = bf1Player[id][PISTOL];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 100) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 250 && roundKills >= 2) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 500 && roundKills >= 3 && roundHSKills >= 1) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 1000 && roundKills >= 4 && roundHSKills >= 2) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_PISTOL] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_PISTOL][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_ASSAULT];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		roundKills = 0;
		roundHSKills = 0;

		get_weapon_round_stats(id, CSW_AK47, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_M4A1, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_GALIL, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_FAMAS, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_SG552, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_AUG, roundKills, roundHSKills);

		weaponKills = bf1Player[id][RIFLE];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 500 && roundKills >= 2) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 1000 && roundKills >= 3 && roundHSKills >= 1) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 2500 && roundKills >= 4 && roundHSKills >= 2) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 5000 && roundKills >= 5 && roundHSKills >= 3) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_ASSAULT] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_ASSAULT][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_SNIPER];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		roundKills = 0;
		roundHSKills = 0;

		get_weapon_round_stats(id, CSW_SCOUT, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_AWP, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_G3SG1, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_SG550, roundKills, roundHSKills);

		weaponKills = bf1Player[id][SNIPER];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 250) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 500 && roundKills >= 2) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 1000 && roundKills >= 3 && roundHSKills >= 1) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 2500 && roundKills >= 4 && roundHSKills >= 2) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_SNIPER] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_SNIPER][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_SUPPORT];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		roundKills = 0;
		roundHSKills = 0;

		get_weapon_round_stats(id, CSW_M249, roundKills, roundHSKills);

		weaponKills = bf1Player[id][M249];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 100) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 250 && roundKills >= 2) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 500 && roundKills >= 3 && roundHSKills >= 1) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 1000 && roundKills >= 4 && roundHSKills >= 2) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_SUPPORT] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_SUPPORT][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_EXPLOSIVES];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		weaponKills = bf1Player[id][GRENADE];

		new explosions = bf1Player[id][EXPLOSIONS];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 50 && explosions >= 10) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 100 && explosions >= 25) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 175 && explosions >= 50) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 250 && explosions >= 100) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_EXPLOSIVES] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_EXPLOSIVES][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_SHOTGUN];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		roundKills = 0;
		roundHSKills = 0;

		get_weapon_round_stats(id, CSW_M3, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_XM1014, roundKills, roundHSKills);

		weaponKills = bf1Player[id][SHOTGUN];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 100) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 250 && roundKills >= 2) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 500 && roundKills >= 3 && roundHSKills >= 1) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 1000 && roundKills >= 4 && roundHSKills >= 2) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_SHOTGUN] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_SHOTGUN][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_SMG];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		roundKills = 0;
		roundHSKills = 0;

		get_weapon_round_stats(id, CSW_MAC10, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_UMP45, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_TMP, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_MP5NAVY, roundKills, roundHSKills);
		get_weapon_round_stats(id, CSW_P90, roundKills, roundHSKills);

		weaponKills = bf1Player[id][SMG];

		switch (badge) {
			case LEVEL_NONE: if (weaponKills >= 100) level = LEVEL_START;
			case LEVEL_START: if (weaponKills >= 250 && roundKills >= 2) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (weaponKills >= 500 && roundKills >= 3 && roundHSKills >= 1) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (weaponKills >= 1000 && roundKills >= 4 && roundHSKills >= 2) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_SMG] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_SMG][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_TIME];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		new degree = bf1Player[id][DEGREE];

		switch (badge) {
			case LEVEL_NONE: if (degree >= 1) level = LEVEL_START;
			case LEVEL_START: if (degree >= 2) level = LEVEL_EXPERIENCED;
			case LEVEL_EXPERIENCED: if (degree >= 3) level = LEVEL_VETERAN;
			case LEVEL_VETERAN: if (degree >= 4) level = LEVEL_MASTER;
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_TIME] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_TIME][level]);
		}
	}

	badge = bf1Player[id][BADGES][BADGE_GENERAL];

	if (badge != LEVEL_MASTER) {
		level = LEVEL_NONE;

		new badges;

		switch (badge) {
			case LEVEL_NONE: {
				for (new i = 0; i < MAX_BADGES - 1; i++) {
					if (bf1Player[id][BADGES][i] >= LEVEL_START) badges++;
				}

				if (badges >= MAX_BADGES - 1) level = LEVEL_START;
			} case LEVEL_START: {
				for (new i = 0; i < MAX_BADGES - 1; i++) {
					if (bf1Player[id][BADGES][i] >= LEVEL_EXPERIENCED) badges++;
				}

				if (badges >= MAX_BADGES - 1) level = LEVEL_EXPERIENCED;
			} case LEVEL_EXPERIENCED: {
				for (new i = 0; i < MAX_BADGES - 1; i++) {
					if (bf1Player[id][BADGES][i] >= LEVEL_VETERAN) badges++;
				}

				if (badges >= MAX_BADGES - 1) level = LEVEL_VETERAN;
			} case LEVEL_VETERAN: {
				for (new i = 0; i < MAX_BADGES - 1; i++) {
					if (bf1Player[id][BADGES][i] >= LEVEL_MASTER) badges++;
				}

				if (badges >= MAX_BADGES - 1) level = LEVEL_MASTER;
			}
		}

		if (level > badge) {
			gained = true;

			bf1Player[id][BADGES][BADGE_GENERAL] = level;

			client_print_color(id, id, "^x04[BF1]^x01 Zdobyles odznake:^x03 %s^x01.", bf1BadgeName[BADGE_GENERAL][level]);
		}
	}

	if (gained) {
		client_cmd(id, "spk %s", bf1Sounds[SOUND_BADGE]);

		save_stats(id, NORMAL);
	}

	check_orders(id);
}

public check_orders(id)
{
	if (!cvarBf1Enabled) return;

	new bool:gained;

	if (!bf1Player[id][ORDERS][ORDER_AIMBOT] && bf1Player[id][HS_KILLS] >= 2500) {
		bf1Player[id][ORDERS][ORDER_AIMBOT] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_AIMBOT][DESIGNATION], bf1Orders[ORDER_AIMBOT][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_ANGEL] && bf1Player[id][ASSISTS] >= 500) {
		bf1Player[id][ORDERS][ORDER_ANGEL] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_ANGEL][DESIGNATION], bf1Orders[ORDER_ANGEL][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_BOMBERMAN] && bf1Player[id][PLANTS] >= 100) {
		bf1Player[id][ORDERS][ORDER_BOMBERMAN] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_BOMBERMAN][DESIGNATION], bf1Orders[ORDER_BOMBERMAN][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_SAPER] && bf1Player[id][DEFUSES] >= 50) {
		bf1Player[id][ORDERS][ORDER_SAPER] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_SAPER][DESIGNATION], bf1Orders[ORDER_SAPER][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_PERSIST] && bf1Player[id][VISITS] >= 100) {
		bf1Player[id][ORDERS][ORDER_PERSIST] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_PERSIST][DESIGNATION], bf1Orders[ORDER_PERSIST][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_DESERV] && (bf1Player[id][GOLD] + bf1Player[id][SILVER]  + bf1Player[id][BRONZE]) >= 100) {
		bf1Player[id][ORDERS][ORDER_DESERV] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_DESERV][DESIGNATION], bf1Orders[ORDER_DESERV][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_MILION] && bf1Player[id][EARNED] >= 1000000) {
		bf1Player[id][ORDERS][ORDER_MILION] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_MILION][DESIGNATION], bf1Orders[ORDER_MILION][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_BULLET] && bf1Player[id][DMG_RECEIVED] >= 50000) {
		bf1Player[id][ORDERS][ORDER_BULLET] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_BULLET][DESIGNATION], bf1Orders[ORDER_BULLET][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_RAMBO] && bf1Player[id][DMG_TAKEN] >= 50000) {
		bf1Player[id][ORDERS][ORDER_RAMBO] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_RAMBO][DESIGNATION], bf1Orders[ORDER_RAMBO][NEEDS]);

		gained = true;
	}

	if (!bf1Player[id][ORDERS][ORDER_SURVIVER] && bf1Player[id][SURVIVED] >= 1000) {
		bf1Player[id][ORDERS][ORDER_SURVIVER] = 1;

		client_print_color(id, id, "^x04[BF1]^x01 Zdobyles order:^x03 %s - %s^x01.", bf1Orders[ORDER_SURVIVER][DESIGNATION], bf1Orders[ORDER_SURVIVER][NEEDS]);

		gained = true;
	}

	if (gained) {
		client_cmd(id, "spk %s", bf1Sounds[SOUND_ORDER]);

		save_stats(id, NORMAL);
	}
}

public most_kills_disconnect()
{
	new players[MAX_PLAYERS], playersNum, player;

	get_players(players, playersNum, "h");

	bf1Server[MOSTKILLS] = 0;
	bf1Server[MOSTKILLSID] = 0;
	bf1Server[MOSTKILLSNAME] = "";

	for (new i = 0; i < playersNum; i++) {
		player = players[i];

		if (bf1Player[player][KILLS] > bf1Server[MOSTKILLS]) {
			bf1Server[MOSTKILLS] = bf1Player[player][KILLS];
			bf1Server[MOSTKILLSID] = player;
		}
	}

	if (!bf1Server[MOSTKILLSID]) return;

	get_user_name(bf1Server[MOSTKILLSID], bf1Server[MOSTKILLSNAME], charsmax(bf1Server[MOSTKILLSNAME]));

	client_print_color(0, bf1Server[MOSTKILLSID], "^x04[BF1]^x03 %s^x01 jest aktualnie liderem we fragach z^x03 %i^x01 zabiciami.", bf1Server[MOSTKILLSNAME], bf1Server[MOSTKILLS]);
}

public most_wins_disconnect()
{
	new players[MAX_PLAYERS], playersNum, player;

	get_players(players, playersNum, "h");

	bf1Server[MOSTWINS] = 0;
	bf1Server[MOSTWINSID] = 0;
	bf1Server[MOSTWINSNAME] = "";

	for (new i = 0; i < playersNum; i++) {
		player = players[i];

		if (bf1Player[player][KILLS] > bf1Server[MOSTWINS]) {
			bf1Server[MOSTWINS] = bf1Player[player][KILLS];
			bf1Server[MOSTWINSID] = player;
		}
	}

	if (!bf1Server[MOSTWINSID]) return;

	get_user_name(bf1Server[MOSTWINSID], bf1Server[MOSTWINSNAME], charsmax(bf1Server[MOSTWINSNAME]));

	client_print_color(0, bf1Server[MOSTWINSID], "^x04[BF1]^x03 %s^x01 jest aktualnie liderem w zwyciestwach z^x03 %i^x01 zlotymi medalami.", bf1Server[MOSTWINSNAME], bf1Server[MOSTWINS]);
}

public highest_rank_disconnect()
{
	new players[32], playersNum, player;

	get_players(players, playersNum, "h");

	bf1Server[HIGHESTRANK] = 0;
	bf1Server[HIGHESTRANKID] = 0;
	bf1Server[HIGHESTRANKNAME] = "";

	for (new i = 0; i < playersNum; i++) {
		player = players[i];

		if (is_ranked_higher(bf1Player[player][RANK], bf1Server[HIGHESTRANK])) {
			bf1Server[HIGHESTRANK] = bf1Player[player][RANK];
			bf1Server[HIGHESTRANKID] = player;
		}
	}

	if (!bf1Server[HIGHESTRANK]) return;

	get_user_name(bf1Server[HIGHESTRANKID], bf1Server[HIGHESTRANKNAME], charsmax(bf1Server[HIGHESTRANKNAME]));

	client_print_color(0, bf1Server[HIGHESTRANKID], "^x04[BF1]^x03 %s^x01 jest aktualnie liderem Rankingu Oficerskiego z ranga^x03 %s^x01!", bf1Server[HIGHESTRANKNAME], bf1RankName[bf1Server[HIGHESTRANK]]);
}

public award_check()
{
	enum _:winners { THIRD, SECOND, FIRST };

	new playerName[winners][MAX_LENGTH], players[MAX_PLAYERS], bestId[winners], bestFrags[winners], bool:newLeader, playersNum, tempFrags, swapFrags, swapId, id;

	get_players(players, playersNum, "h");

	if (!playersNum) return;

	for (new i = 0; i < playersNum; i++) {
		id = players[i];

		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

		tempFrags = get_user_frags(id);

		if (tempFrags > bestFrags[THIRD]) {
			bestFrags[THIRD] = tempFrags;
			bestId[THIRD] = id;

			if (tempFrags > bestFrags[SECOND]) {
				swapFrags = bestFrags[SECOND];
				swapId = bestId[SECOND];
				bestFrags[SECOND] = tempFrags;
				bestId[SECOND] = id;
				bestFrags[THIRD] = swapFrags;
				bestId[THIRD] = swapId;

				if (tempFrags > bestFrags[FIRST]) {
					swapFrags = bestFrags[FIRST];
					swapId = bestId[FIRST];
					bestFrags[FIRST] = tempFrags;
					bestId[FIRST] = id;
					bestFrags[SECOND] = swapFrags;
					bestId[SECOND] = swapId;
				}
			}
		}
	}

	if (!bestId[FIRST]) return;

	bf1Player[bestId[THIRD]][BRONZE]++;
	bf1Player[bestId[SECOND]][SILVER]++;
	bf1Player[bestId[FIRST]][GOLD]++;

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(player)) continue;

		save_stats(player, MAP_END);
	}

	for (new i = 0; i < 3; i++) {
		get_user_name(bestId[i], playerName[i], charsmax(playerName[]));
	}

	if (bf1Player[bestId[FIRST]][GOLD] > bf1Server[MOSTSERVERWINS]) {
		newLeader = true;

		bf1Server[MOSTSERVERWINS] = bf1Player[bestId[FIRST]][GOLD];

		formatex(bf1Server[MOSTSERVERWINSNAME], charsmax(bf1Server[MOSTSERVERWINSNAME]), playerName[FIRST]);
	}

	client_print_color(0, 0, "^x04[BF1]^x01 Gratulacje dla^x03 Zwyciezcow^x01!");
	client_print_color(0, 0, "^x04[BF1]^x03 %s^x01 - Zloty Medal -^x03 %i^x01 Zabojstw%s.", playerName[FIRST], bestFrags[FIRST], newLeader ? " - Wygrywa" : "");
	client_print_color(0, 0, "^x04[BF1]^x03 %s^x01 - Srebrny Medal -^x03 %i^x01 Zabojstw.", playerName[SECOND], bestFrags[SECOND]);
	client_print_color(0, 0, "^x04[BF1]^x03 %s^x01 - Brazowy Medal -^x03 %i^x01 Zabojstw.", playerName[THIRD], bestFrags[THIRD]);
}

public get_weapon_round_stats(id, weapon, &roundKills, &roundHSKills)
{
	new stats[8], hits[8];

	get_user_wrstats(id, weapon, stats, hits);

	roundKills += stats[0];
	roundHSKills += stats[2];
}

bool:is_ranked_higher(rank1, rank2)
	return (bf1RankOrder[rank1] > bf1RankOrder[rank2]) ? true : false;

public chat_prefix(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);

	if (!is_user_connected(id)) return PLUGIN_CONTINUE;

	new tempMessage[192], message[192], chatPrefix[64], playerName[MAX_LENGTH];

	get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

	formatex(chatPrefix, charsmax(chatPrefix), "^x04[%s]", bf1RankName[bf1Player[id][RANK]]);

	if (!equal(tempMessage, "#Cstrike_Chat_All")) {
		add(message, charsmax(message), chatPrefix);
		add(message, charsmax(message), " ");
		add(message, charsmax(message), tempMessage);
	} else {
		get_user_name(id, playerName, charsmax(playerName));

		get_msg_arg_string(4, tempMessage, charsmax(tempMessage));
		set_msg_arg_string(4, "");

		add(message, charsmax(message), chatPrefix);
		add(message, charsmax(message), "^x03 ");
		add(message, charsmax(message), playerName);
		add(message, charsmax(message), "^x01 :  ");
		add(message, charsmax(message), tempMessage);
	}

	set_msg_arg_string(2, message);

	return PLUGIN_CONTINUE;
}

public block_message()
{
	if (get_msg_argtype(2) == ARG_STRING) {
		new message[MAX_LENGTH];

		get_msg_arg_string(2, message, charsmax(message));

		if(equali(message, "#Cannot_Carry_Anymore")) return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public flashbang_buy(id)
{
	if (bf1Player[id][BADGES][BADGE_GENERAL]) {
		handle_buy(id, CSW_FLASHBANG, 0);
	}
}

public hegrenade_buy(id)
{
	if (bf1Player[id][BADGES][BADGE_GENERAL]) {
		handle_buy(id, CSW_HEGRENADE, 0);
	}
}

public smokegrenade_buy(id)
{
	if (bf1Player[id][BADGES][BADGE_GENERAL]) {
		handle_buy(id, CSW_SMOKEGRENADE, 0);
	}
}

public handle_buy(id, grenade, noCost)
{
	if(!is_user_alive(id) && get_user_team(id) < 1 && get_user_team(id) > 2 && !cs_get_user_buyzone(id) && !noCost) return PLUGIN_CONTINUE;

	new maxAmmo, cost, badge = bf1Player[id][BADGES][BADGE_GENERAL];

	switch(grenade)
	{
		case CSW_FLASHBANG: maxAmmo = badge > LEVEL_NONE ? (badge > LEVEL_EXPERIENCED ? 4 : 3) : 2, cost = 200;
		case CSW_HEGRENADE: maxAmmo = badge > LEVEL_START ? 2 : 1, cost = 300;
		case CSW_SMOKEGRENADE: maxAmmo = badge > LEVEL_VETERAN ? 2 : 1, cost = 300;
	}

	if (!noCost) {
		new Float:buyTime = get_cvar_float("mp_buytime") * 60.0;
		new Float:timePassed = get_gametime() - gameTime;

		if (floatcmp(timePassed, buyTime) == 1) return PLUGIN_HANDLED;

		if (cs_get_user_money(id) - cost <= 0) {
			client_print(id, print_center, "You have insufficent funds!");

			return PLUGIN_HANDLED;
		}
	}

	if (cs_get_user_bpammo(id, grenade) == maxAmmo) {
		if (!noCost) client_print(id, print_center, "You cannot carry anymore!");

		return PLUGIN_HANDLED;
	}

	give_grenade(id, grenade);

	if (!noCost) cs_set_user_money(id, cs_get_user_money(id) - cost, 1);

	return PLUGIN_CONTINUE;
}

public give_grenade(id, grenade)
{
	new grenades = cs_get_user_bpammo(id, grenade);

	if (!grenades) {
		switch(grenade) {
			case CSW_FLASHBANG: give_item(id, "weapon_flashbang");
			case CSW_HEGRENADE: give_item(id, "weapon_hegrenade");
			case CSW_SMOKEGRENADE: give_item(id, "weapon_smokegrenade");
		}
	}

	cs_set_user_bpammo(id, grenade, grenades + 1);

	emit_sound(id, CHAN_WEAPON, bf1Sounds[SOUND_GRENADE], 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public touch_grenades(ent, id)
{
	if (!is_valid_ent(ent) || !is_user_alive(id)) return PLUGIN_CONTINUE;

	if (entity_get_int(ent, EV_INT_iuser1)) return PLUGIN_HANDLED;

	new model[64];

	entity_get_string(ent, EV_SZ_model, model, charsmax(model));

	new grenade = check_grenade_model(model);

	if (grenade != -1) {
		new ammo = cs_get_user_bpammo(id, grenade), maxAmmo, badge = bf1Player[id][BADGES][BADGE_GENERAL];

		switch(grenade) {
			case CSW_FLASHBANG: maxAmmo = badge > LEVEL_NONE ? (badge > LEVEL_EXPERIENCED ? 4 : 3) : 2;
			case CSW_HEGRENADE: maxAmmo = badge > LEVEL_START ? 2 : 1;
			case CSW_SMOKEGRENADE: maxAmmo = badge > LEVEL_VETERAN ? 2 : 1;
		}

		if (maxAmmo <= 0) return PLUGIN_CONTINUE;

		if (!ammo) {
			set_entity_visibility(ent, 0);

			entity_set_int(ent, EV_INT_iuser1, 1);

			return PLUGIN_CONTINUE;
		}

		if (ammo < maxAmmo) {
			set_entity_visibility(ent, 0);

			entity_set_int(ent, EV_INT_iuser1, 1);

			give_grenade(id, grenade);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public check_grenade_model(model[])
{
	if (equal(model, "models/w_flashbang.mdl" )) return CSW_FLASHBANG;
	else if (equal(model, "models/w_hegrenade.mdl")) return CSW_HEGRENADE;
	else if (equal(model, "models/w_smokegrenade.mdl")) return CSW_SMOKEGRENADE;

	return -1;
}

public display_advertisement(id)
{
	id -= TASK_AD;

	if (!cvarBf1Enabled) return;

	client_print_color(id, id, "^x04[BF1]^x01 Ten serwer uzywa^x03 %s^x01 w wersji^x03 %s^x01 autorstwa^x03 %s^x01.", PLUGIN, VERSION, AUTHOR);
	client_print_color(id, id, "^x04[BF1]^x01 Wpisz^x03 /bf1^x01 lub^x03 /pomoc^x01, aby uzyskac wiecej informacji.");
}

public display_hud(id)
{
	id -= TASK_HUD;

	if (!cvarBf1Enabled || !is_user_connected(id)) return PLUGIN_CONTINUE;

	new target = id;

	if (!is_user_alive(id)) {
		target = pev(id, pev_iuser2);

		if (!bf1Player[target][HUD]) {
			set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.3, 0.0, 0.0, 4);
		} else {
			set_dhudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.3, 0.0, 0.0);
		}
	} else {
		if (!bf1Player[target][HUD]) {
			set_hudmessage(bf1Player[target][HUD_RED], bf1Player[target][HUD_GREEN], bf1Player[target][HUD_BLUE], float(bf1Player[target][HUD_POSX]) / 100.0, float(bf1Player[target][HUD_POSY]) / 100.0, 0, 0.0, 0.3, 0.0, 0.0, 4);
		} else {
			set_dhudmessage(bf1Player[target][HUD_RED], bf1Player[target][HUD_GREEN], bf1Player[target][HUD_BLUE], float(bf1Player[target][HUD_POSX]) / 100.0, float(bf1Player[target][HUD_POSY]) / 100.0, 0, 0.0, 0.3, 0.0, 0.0);
		}
	}

	if (!target) return PLUGIN_CONTINUE;

	static info[512], seconds, minutes, hours;

	if (!get_bit(target, loaded)) formatex(info, charsmax(info), "[%s] Trwa wczytywanie danych...", PLUGIN);
	else {
		seconds = (bf1Player[target][TIME] + get_user_time(target)), minutes = 0, hours = 0;

		while (bf1Player[target][DEGREE] < sizeof(bf1Degrees) - 1 && seconds / 3600 >= str_to_num(bf1Degrees[bf1Player[target][DEGREE] + 1][HOURS])) {
			bf1Player[target][DEGREE]++;
		}

		while(seconds >= 60) {
			seconds -= 60;
			minutes++;

			if (minutes >= 60) {
				minutes -= 60;
				hours++;
			}
		}

		if (bf1Player[target][HUD] < TYPE_STATUSTEXT) {
			formatex(info, charsmax(info), "[%s]^n[Ranga]: %s^n[Odznaki]: %d/%d^n[Ordery]: %d/%d^n[Zabicia]: %d/%d^n[Czas Gry]: %i h %i min %i s^n[Stopien]: %s", PLUGIN, bf1RankName[bf1Player[target][RANK]], bf1Player[target][BADGES_COUNT], MAX_BADGES * 4, bf1Player[target][ORDERS_COUNT], MAX_ORDERS, bf1Player[target][KILLS], bf1Player[target][NEXT_RANK], hours, minutes, seconds, bf1Degrees[bf1Player[target][DEGREE]][DEGREES]);
		} else {
			formatex(info, charsmax(info), "[BF1] Zabicia: %d/%d  Ranga: %s Odznaki: %d/%d", bf1Player[target][KILLS], bf1Player[target][NEXT_RANK], bf1RankName[bf1Player[target][RANK]], bf1Player[target][BADGES_COUNT], MAX_BADGES * 4);
		}
	}

	switch (bf1Player[target][HUD]) {
		case TYPE_HUD: ShowSyncHudMsg(id, hudSync, info);
		case TYPE_DHUD: show_dhudmessage(id, info);
		case TYPE_STATUSTEXT: {
			message_begin(MSG_ONE_UNRELIABLE, msgStatusText, _, id);
			write_byte(0);
			write_string(info);
			message_end();
		}
	}

	return PLUGIN_CONTINUE;
}

public display_help()
{
	switch (random_num(1, 4)) {
		case 1: client_print_color(0, 0, "^x04[BF1]^x01 Mozesz spersonalizowac wyswietlanie informacji w HUD wpisujac^x03 /hud");
		case 2: client_print_color(0, 0, "^x04[BF1]^x01 Chcesz dowiedziec sie wiecej o modzie BF1? Wpisz komende^x03 /pomoc");
		case 3: client_print_color(0, 0, "^x04[BF1]^x01 Aby wejsc do glownego menu BF1 nalezy wpisac komende^x03 /bf1");
		case 4: client_print_color(0, 0, "^x04[BF1]^x01 W paczkach wypadajacych z graczy znajdziesz^x03 hp, fragi, kase, odznaki^x01!");
	}
}

public cmd_say(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new message[64];

	read_args(message, charsmax(message));
	remove_quotes(message);

	if (equal(message, "/whostats", 9)) {
		new player = cmd_target(id, message[10], 0);

		if (!player || is_user_bot(player) || is_user_hltv(player)) {
			client_print_color(id, id, "^x04[BF1]^x01 Przepraszamy, gracza^x03 %s^x01 nie ma w tej chwili na serwerze!", message[10]);

			return PLUGIN_CONTINUE;
		}

		cmd_stats(id, player);

		return PLUGIN_CONTINUE;
	}

	if (equal(message, "/whois", 6)) {
		new player = cmd_target(id, message[7], 0);

		if (!player || is_user_bot(player) || is_user_hltv(player)) {
			client_print_color(id, id, "^x04[BF1]^x01 Przepraszamy, gracza^x03 %s^x01 nie ma w tej chwili na serwerze!", message[7]);

			return PLUGIN_CONTINUE;
		}

		cmd_badges(id, player);

		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public cmd_rank_help(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new motdData[2048], tempData[128];

	formatex(motdData, charsmax(motdData), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^"><strong>Wymagania Rang</strong><br><br>");
	add(motdData, charsmax(motdData), tempData);

	for (new i = 0; i < MAX_RANKS - 1; i++) {
		formatex(tempData, charsmax(tempData), "%s - %d Zabic<br>", bf1RankName[i], bf1RankKills[i]);
		add(motdData, charsmax(motdData), tempData);

		switch (i) {
			case 9: {
				formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz %d Odznak<br>", bf1RankName[17], bf1RankName[9], MAX_BADGES);
				add(motdData, charsmax(motdData), tempData);
			} case 12: {
				formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz %d Odznak<br>", bf1RankName[18], bf1RankName[12], floatround(MAX_BADGES * 2.5));
				add(motdData, charsmax(motdData), tempData);
			}
		}
	}

	formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz %d Odznaki<br>", bf1RankName[19], bf1RankName[15], MAX_BADGES * 4);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz %d Zabic<br>", bf1RankName[16], bf1RankName[19], bf1RankKills[MAX_RANKS - 1]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz pozycja w Top15 rankingu BF1<br>", bf1RankName[20], bf1RankName[16]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz pozycja Top3 rankingu BF1<br>", bf1RankName[21], bf1RankName[16]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz pozycja Top2 rankingu BF1<br>", bf1RankName[22], bf1RankName[16]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "%s - Wymagane %s oraz pozycja Top1 rankingu BF1<br></font></body></html>", bf1RankName[23], bf1RankName[16]);
	add(motdData, charsmax(motdData), tempData);

	show_motd(id, motdData, "BF1: Wymagania Rang");

	return PLUGIN_CONTINUE;
}

public cmd_server_stats(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new motdData[2048], tempData[256];

	formatex(motdData, charsmax(motdData), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^">");
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "<strong>Obecne Statystyki</strong><br><br>Najwyzsza Ranga: %s (%s)<br><br>Najwiecej Zabic: %s (%i)<br><br>Najwiecej Zwyciestw: %s (%i)<br><br>",
	bf1Server[HIGHESTRANKNAME], bf1RankName[bf1Server[HIGHESTRANK]], bf1Server[MOSTKILLSNAME], bf1Server[MOSTKILLS], bf1Server[MOSTWINSNAME], bf1Server[MOSTWINS]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData,charsmax(tempData), "<strong>Statystyki Serwera</strong><br><br>Najwyzsza Ranga: %s (%s)<br><br>Najwiecej Zabic: %s (%i)<br><br>Najwiecej Zwyciestw: %s (%i)<br><br></font></body></html>",
	bf1Server[HIGHESTSERVERRANKNAME], bf1RankName[bf1Server[HIGHESTSERVERRANK]], bf1Server[MOSTSERVERKILLSNAME], bf1Server[MOSTSERVERKILLS], bf1Server[MOSTSERVERWINSNAME], bf1Server[MOSTSERVERWINS]);
	add(motdData, charsmax(motdData), tempData);

	show_motd(id, motdData, "BF1: Statystyki Serwera");

	return PLUGIN_CONTINUE;
}

public cmd_badge_help(id, badge)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new motdData[128], badgeUrl[64], title[32];

	switch (badge) {
		case 1: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_nozem.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Nozem");
		} case 2: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_pistoletami.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Pistoletami");
		} case 3: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_bronia_szturmowa.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Bronia Szturmowa");
		} case 4: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_bronia_snajperska.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Bronia Snajperska");
		} case 5: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_bronia_wsparcia.htm");
			formatex(title, charsmax(title), "Bronia Wsparcia");
		} case 6: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_bronia_wybuchowa.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Bronia Wybuchowa");
		} case 7: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_shotgunami.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Bronia Shotgunami");
		} case 8: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_smg.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Bronia SMG");
		} case 9: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_czasowa.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Czasowa");
		} case 10: {
			formatex(badgeUrl, charsmax(badgeUrl), "walka_ogolna.htm");
			formatex(title, charsmax(title), "BF1: Odznaka Walka Ogolna");
		}
	}

	formatex(motdData, charsmax(motdData), "%s/%s", equal(cvarHelpUrl, "") ? configPath : cvarHelpUrl, badgeUrl);

	show_motd(id, motdData, title);

	return PLUGIN_CONTINUE;
}

public cmd_badges(id, player)
{
	new motdData[2048], tempData[128], playerName[MAX_NAME];

	get_user_name(player, playerName, charsmax(playerName));

	formatex(motdData, charsmax(motdData), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^"><strong><b>");
	formatex(tempData, charsmax(tempData), "Statystyki Rang i Odznak dla gracza %s</strong></b><br><br>Ranking: %s<br><br>Zdobyte Odznaki: %d/%d<br>", playerName, bf1RankName[bf1Player[player][RANK]], bf1Player[player][BADGES_COUNT], MAX_BADGES * 4);
	add(motdData, charsmax(motdData), tempData);

	for (new i = 0; i < MAX_BADGES; i++) {
		if (bf1Player[player][BADGES][i]) {
			formatex(tempData, charsmax(tempData), "%s - %s<br>", bf1BadgeName[i][bf1Player[player][BADGES][i]], bf1BadgeInfo[i]);
			add(motdData, charsmax(motdData), tempData);
		}
	}

	formatex(tempData, charsmax(tempData), "<br>Zdobyte Ordery: %d/%d<br>", bf1Player[player][ORDERS_COUNT], MAX_ORDERS);
	add(motdData, charsmax(motdData), tempData);

	for (new i = 0; i < MAX_ORDERS; i++) {
		if (bf1Player[player][ORDERS][i]) {
			formatex(tempData, charsmax(tempData), "%s - %s<br>", bf1Orders[i][DESIGNATION], bf1Orders[i][NEEDS]);
			add(motdData, charsmax(motdData), tempData);
		}
	}

	add(motdData,charsmax(motdData),"</font></body></html>");

	show_motd(id, motdData, "BF1: Informacje o Graczu");

 	return PLUGIN_CONTINUE;
}

public cmd_ranks(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new motdData[2048], tempData[128], playerName[MAX_LENGTH], players[MAX_PLAYERS], player, playersNum;

	formatex(motdData,charsmax(motdData),"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"white^"><strong><b>Ranking Graczy</strong></b><br><br>");

	get_players(players, playersNum);

	for (new i = 0; i < playersNum; i++) {
		player = players[i];

		if (is_user_bot(player) || is_user_hltv(player)) continue;

		get_user_name(player, playerName, charsmax(playerName));

		formatex(tempData, charsmax(tempData), "%s - %s<br>", playerName, bf1RankName[bf1Player[player][RANK]]);
		add(motdData, charsmax(motdData), tempData);
	}

	add(motdData, charsmax(motdData), "</font></body></html>");

	show_motd(id, motdData, "BF1: Ranking Graczy");

	return PLUGIN_CONTINUE;
}

public cmd_orders(id)
{
	new motdData[1024], tempData[256];

	formatex(motdData, charsmax(motdData), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FF0000^"><strong><center>Lista Orderow:</font><br><font size=^"1^" face=^"verdana^" color=^"FFFFFF^">");

	for (new i; i < MAX_ORDERS; i++) {
		formatex(tempData, charsmax(tempData), "%s - %s <br>", bf1Orders[i][DESIGNATION], bf1Orders[i][NEEDS]);
		add(motdData, charsmax(motdData), tempData);
	}

	add(motdData,charsmax(motdData), "</font></center></body></html>");

	show_motd(id, motdData, "Lista Orderow");

	return PLUGIN_CONTINUE;
}

public cmd_help(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new motdData[256], helpUrl[128];

	if (equal(cvarHelpUrl, "")) {
		formatex(helpUrl, charsmax(helpUrl), "%s/bf1webdocs/pomoc.htm", configPath);
		show_motd(id, helpUrl, "BF1: Pomoc");
	} else {
		formatex(motdData, charsmax(motdData), "<html><iframe src =^"%s/pomoc.htm^" scrolling=^"yes^" width=^"800^" height=^"600^"></iframe></html>", cvarHelpUrl);
		show_motd(id, motdData, "BF1: Pomoc");
	}

	return PLUGIN_CONTINUE;
}

public cmd_my_stats(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	cmd_stats(id, id);

	return PLUGIN_CONTINUE;
}

public cmd_stats(id, player)
{
	new motdData[2048], tempData[256], playerName[MAX_LENGTH], stats[8], hits[8], ranked = get_user_stats(player, stats, hits), rank = bf1Player[player][RANK], nextRank;

	switch(rank) {
		case 16, 19, 20, 21, 22, 23: nextRank = 15;
		case 17: nextRank = 7;
		case 18: nextRank = 8;
		default: nextRank = rank;
	}

	++nextRank;

	get_user_name(player, playerName, charsmax(playerName));

	formatex(motdData, charsmax(motdData), "<html><style type=^"text/css^">h1{font-size:10px;color:c4c4c4;margin:0}h2{font-size:12px;color:white;margin:0}</style>");
	formatex(tempData, charsmax(tempData), "<body bgcolor=^"#474642^"><h2><strong>Statystyki Gracza: %s</strong><br>(Aktualizowane co Runde)<br><br><table gained=^"0^">", playerName);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "<tr><td align=^"left^"><h2>Ranking: #%d<br><br>Odznaki: %d/%d<br><br>Ordery: %d/%d<br><br>Ranga: %s<br><br>Zabicia: %d<br><br>Zabicia z HS: %d<br><br>Asysty: %d<br><br>",
	ranked, bf1Player[id][BADGES_COUNT], MAX_BADGES * 4, bf1Player[id][ORDERS_COUNT], MAX_ORDERS, bf1RankName[rank], bf1Player[player][KILLS], bf1Player[player][HS_KILLS], bf1Player[player][ASSISTS]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData,charsmax(tempData),"<h2>Przetrwane Rundy: %d<br><br><h2>Zdobyte Pieniadze: %d<br><br>Zdobyte Medale: %d<br><h1>Zlote: %d<br>Srebrne: %d<br>Brazowe: %d",
	bf1Player[player][SURVIVED], bf1Player[player][EARNED], bf1Player[player][GOLD] + bf1Player[player][SILVER] + bf1Player[player][BRONZE], bf1Player[player][GOLD], bf1Player[player][SILVER], bf1Player[player][BRONZE]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData,charsmax(tempData),"<br><br><h2>Obrazenia:<br><h1>Zadane: %d<br>Otrzymane: %d<br><br><h2>Bomby:<h1>Podlozone: %d<br>Wysadzone: %d<br>Rozbrojone %d<br><br><h2>Uratowane Hosty: %d<td width=^"120^"></td>",
	bf1Player[player][DMG_TAKEN], bf1Player[player][DMG_RECEIVED], bf1Player[player][XM1014], bf1Player[player][PLANTS], bf1Player[player][EXPLOSIONS], bf1Player[player][DEFUSES], bf1Player[player][RESCUES]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "<td><br><h2>Zabicia z Noza: %d<br><br>Zabicia Pistoletami: %d<h1>Glock: %d<br>USP: %d<br>P228: %d<br>Deagle: %d<br>FiveSeven: %d<br>Dual Elites: %d<br><br>",
	bf1Player[player][KNIFE], bf1Player[player][PISTOL], bf1Player[player][GLOCK], bf1Player[player][USP], bf1Player[player][P228], bf1Player[player][DEAGLE], bf1Player[player][FIVESEVEN], bf1Player[player][ELITES]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "<h2>Zabicia Snajperkami: %d<h1>Scout: %d<br>AWP: %d<br>G3SG1: %d<br>SG550: %d<br><br>",
	bf1Player[player][SNIPER], bf1Player[player][SCOUT], bf1Player[player][AWP], bf1Player[player][G3SG1], bf1Player[player][SG550]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData, charsmax(tempData), "<h2>Zabicia Karabinami: %d<h1>AK47: %d<br>M4A1: %d<br>Galil: %d<br>Famas: %d<br>SG552: %d<br>AUG: %d<br><br><h2>Zabicia z M249: %d<br><br>",
	bf1Player[player][RIFLE], bf1Player[player][AK47], bf1Player[player][M4A1], bf1Player[player][GALIL], bf1Player[player][FAMAS], bf1Player[player][SG552], bf1Player[player][AUG], bf1Player[player][M249]);
	add(motdData, charsmax(motdData), tempData);

	formatex(tempData,charsmax(tempData), "Zabicia z SMG: %d<h1>MAC10: %d<br>TMP: %d<br>MP5: %d<br>UMP45: %d<br>P90: %d<br><br><h2>Zabicia Granatami: %d<br><br>Zabicia Shotgunami: %d<h1>M3: %d<br>XM1014: %d</tr></table></body></html>",
	bf1Player[player][SMG], bf1Player[player][MAC10], bf1Player[player][TMP], bf1Player[player][MP5], bf1Player[player][UMP45], bf1Player[player][P90], bf1Player[player][GRENADE], bf1Player[player][SHOTGUN], bf1Player[player][M3], bf1Player[player][XM1014]);
	add(motdData, charsmax(motdData), tempData);

	show_motd(id, motdData, "BF1: Statystyki Gracza");
}

public menu_hud(id)
{
	new menuData[128], menu = menu_create("\yBF1: \rKonfiguracja HUD", "menu_hud_handle");

	format(menuData, charsmax(menuData), "\wSposob \yWyswietlania: \r%s", bf1Player[id][HUD] > TYPE_HUD ? (bf1Player[id][HUD] > TYPE_DHUD ? "StatusText" : "DHUD") : "HUD");
	menu_additem(menu, menuData);

	format(menuData, charsmax(menuData), "\wKolor \yCzerwony: \r%i", bf1Player[id][HUD_RED]);
	menu_additem(menu, menuData);

	format(menuData, charsmax(menuData), "\wKolor \yZielony: \r%i", bf1Player[id][HUD_GREEN]);
	menu_additem(menu, menuData);

	format(menuData, charsmax(menuData), "\wKolor \yNiebieski: \r%i", bf1Player[id][HUD_BLUE]);
	menu_additem(menu, menuData);

	format(menuData, charsmax(menuData), "\wPolozenie \yOs X: \r%i%%", bf1Player[id][HUD_POSX]);
	menu_additem(menu, menuData);

	format(menuData, charsmax(menuData), "\wPolozenie \yOs Y: \r%i%%^n", bf1Player[id][HUD_POSY]);
	menu_additem(menu, menuData);

	format(menuData, charsmax(menuData), "\yDomyslne \rUstawienia");
	menu_additem(menu, menuData);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz", 0);

	menu_display(id, menu);
}

public menu_hud_handle(id, menu, item)
{
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_CONTINUE;
	}

	switch (item) {
		case 0: {
			if (++bf1Player[id][HUD] > TYPE_STATUSTEXT) bf1Player[id][HUD] = TYPE_HUD;

			if (bf1Player[id][HUD] != TYPE_STATUSTEXT) {
				message_begin(MSG_ONE_UNRELIABLE, msgStatusText, _, id);
				write_byte(0);
				write_short(0);
				message_end();
			}
		}
		case 1: if((bf1Player[id][HUD_RED] += 15) > 255) bf1Player[id][HUD_RED] = 0;
		case 2: if((bf1Player[id][HUD_GREEN] += 15) > 255) bf1Player[id][HUD_GREEN] = 0;
		case 3: if((bf1Player[id][HUD_BLUE] += 15) > 255) bf1Player[id][HUD_BLUE] = 0;
		case 4: if((bf1Player[id][HUD_POSX] += 3) > 100) bf1Player[id][HUD_POSX] = 0;
		case 5: if((bf1Player[id][HUD_POSY] += 3) > 100) bf1Player[id][HUD_POSY] = 0;
		case 6: {
			bf1Player[id][HUD] = TYPE_HUD;
			bf1Player[id][HUD_RED] = 255;
			bf1Player[id][HUD_GREEN] = 128;
			bf1Player[id][HUD_BLUE] = 0;
			bf1Player[id][HUD_POSX] = 66;
			bf1Player[id][HUD_POSY] = 6;
		}
	}

	menu_hud(id);

	save_stats(id, NORMAL);

	return PLUGIN_CONTINUE;
}

public cmd_add_badge(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4)) return PLUGIN_HANDLED;

	new playerName[MAX_LENGTH], badgeIndex[4], badgeLevel[4];

	read_argv(1, playerName, charsmax(playerName));
	read_argv(2, badgeIndex, charsmax(badgeIndex));
	read_argv(3, badgeLevel, charsmax(badgeLevel));

	new badge = str_to_num(badgeIndex) - 1, level = str_to_num(badgeLevel), player = cmd_target(id, playerName, 0);

	if (!player) {
		console_print(id, "[BF1] Nie znaleziono podanego gracza!", playerName);

		return PLUGIN_HANDLED;
	}

	if (badge >= MAX_BADGES || badge < 0) {
		console_print(id, "[BF1] Podales bledny numer odznaki!");

		return PLUGIN_HANDLED;
	}

	if (level > MAX_LEVELS || level < 0) {
		console_print(id, "[BF2] Podales bledny poziom odznaki!");

		return PLUGIN_HANDLED;
	}

	new adminName[32];

	get_user_name(id, adminName, charsmax(adminName));
	get_user_name(player, playerName, charsmax(playerName));

	client_print_color(player, player, "^x04[BF1]^x01 Otrzymales odznake:^x03 %s^x01.", bf1BadgeName[badge][level]);
	client_print_color(id, id, "^x04[BF1]^x01 Przyznales odznake^x03 %s^x01 graczowi^x03 %s^x01.", bf1BadgeName[badge][level], playerName);

	log_to_file(LOG_FILE, "[BF1-ADMIN] %s przyznal odznake %s graczowi %s.", adminName, bf1BadgeName[badge][level], playerName);

	bf1Player[player][BADGES][badge] = level;

	save_stats(player, NORMAL);

	check_rank(player);

	return PLUGIN_HANDLED;
}

public cmd_add_badge_sql(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4)) return PLUGIN_HANDLED;

	new playerName[32], badgeIndex[4], badgeLevel[4];

	read_argv(1, playerName, charsmax(playerName));
	read_argv(2, badgeIndex, charsmax(badgeIndex));
	read_argv(3, badgeLevel, charsmax(badgeLevel));

	new badge = str_to_num(badgeIndex) - 1, level = str_to_num(badgeLevel);

	if (badge >= MAX_BADGES || badge < 0) {
		console_print(id, "[BF1] Podales bledny numer odznaki!");

		return PLUGIN_HANDLED;
	}

	if (level > MAX_LEVELS || level < 0) {
		console_print(id, "[BF2] Podales bledny poziom odznaki!");

		return PLUGIN_HANDLED;
	}

	new tempData[512], playerNameSafe[MAX_SAFE_NAME], adminName[MAX_NAME], data[1];

	data[0] = id;

	mysql_escape_string(playerName, playerNameSafe, charsmax(playerNameSafe));

	formatex(tempData, charsmax(tempData), "UPDATE bf1 SET badge%i = %i WHERE playerid=^"%s^"", badge + 1, level, playerNameSafe);

	SQL_ThreadQuery(sql, "cmd_add_badge_sql_handle", tempData, data, 1);

	get_user_name(id, adminName, charsmax(adminName));

	client_print_color(id, id, "^x04[BF1]^x01 Przyznales odznake^x03 %s^x01 graczowi^x03 %s^x01.", bf1BadgeName[badge][level], playerName);

	log_to_file(LOG_FILE, "[BF1-ADMIN] %s przyznal odznake %s graczowi %s.", adminName, bf1BadgeName[badge][level], playerName);

	return PLUGIN_HANDLED;
}

public cmd_add_badge_sql_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState) {
		log_to_file(LOG_FILE, "SQL Error: %s (%d)", error, errorCode);

		return PLUGIN_CONTINUE;
	}

	SQL_FreeHandle(query);

	return PLUGIN_CONTINUE;
}

public check_time(id)
{
	id -= TASK_TIME;

	if (!get_bit(id, visitInfo)) return PLUGIN_CONTINUE;

	if (!get_bit(id, loaded)) {
		set_task(3.0, "check_time", id + TASK_TIME);

		return PLUGIN_CONTINUE;
	}

	new time = get_systime(), year, month, visitMonth, day, visitDay, hour, minute, second;

	UnixToTime(time, year, month, day, hour, minute, second, UT_TIMEZONE_SERVER);

	client_print_color(id, id, "^x04[BF1]^x01 Aktualnie jest godzina^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", hour, minute, second, day, month, year);

	if (bf1Player[id][FIRST_VISIT] == bf1Player[id][LAST_VISIT]) {
		client_print_color(id, id, "^x04[BF1]^x01 To twoja^x03 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!");
	} else {
		UnixToTime(bf1Player[id][LAST_VISIT], year, visitMonth, visitDay, hour, minute, second, UT_TIMEZONE_SERVER);

		if (month == visitMonth && day == visitDay) {
			client_print_color(id, id, "^x04[BF1]^x01 Twoja ostatnia wizyta miala miejsce^x03 dzisiaj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", hour, minute, second);
		} else if (month == visitMonth && day - 1 == visitDay) {
			client_print_color(id, id, "^x04[BF1]^x01 Twoja ostatnia wizyta miala miejsce^x03 wczoraj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", hour, minute, second);
		} else {
			client_print_color(id, id, "^x04[BF1]^x01 Twoja ostatnia wizyta:^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", hour, minute, second, visitDay, visitMonth, year);
		}
	}

	rem_bit(id, visitInfo);

	return PLUGIN_CONTINUE;
}

public cmd_time(id)
{
	new tempData[512], data[1];

	data[0] = id;

	format(tempData,charsmax(tempData), "SELECT COUNT(*) AS rank FROM bf1 WHERE time >= (SELECT time FROM bf1 WHERE name = ^"%s^")", bf1Player[id][SAFE_NAME]);

	SQL_ThreadQuery(sql, "cmd_time_handle", tempData, data, 1);
}

public cmd_time_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Time - Could not connect to SQL database.  [%d] %s", errorCode, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Time - Query failed. [%d] %s", errorCode, error);

		return PLUGIN_CONTINUE;
	}

	new id = data[0], rank = SQL_ReadResult(query, 0), seconds = (bf1Player[id][TIME] + get_user_time(id)), minutes, hours;

	while (seconds >= 60) {
		seconds -= 60;
		minutes++;

		if (minutes >= 60)
		{
			minutes -= 60;
			hours++;
		}
	}

	client_print_color(id, id, "^x04[BF1]^x01 Twoj czas gry wynosi^x03 %i h %i min %i s^x01. Zajmujesz^x03 %i^x01 miejsce w rankingu.", hours, minutes, seconds, rank);

	return PLUGIN_CONTINUE;
}

public cmd_degrees(id)
{
	new motdData[1024], tempData[256];

	formatex(motdData, charsmax(motdData), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FF0000^"><strong><center>Lista Stopni:</font><br><font size=^"1^" face=^"verdana^" color=^"FFFFFF^">");

	for (new i; i < sizeof(bf1Degrees); i++) {
		formatex(tempData, charsmax(tempData), "%s <br>", bf1Degrees[i][DESC]);
		add(motdData, charsmax(motdData), tempData);
	}

	add(motdData,charsmax(motdData), "</font></center></body></html>");

	show_motd(id, motdData, "Lista Stopni");

	return PLUGIN_CONTINUE;
}

public cmd_time_top(id)
{
	new tempData[512], data[1];

	data[0] = id;

	format(tempData, charsmax(tempData), "SELECT name, time FROM bf1 ORDER BY time DESC LIMIT 15");

	SQL_ThreadQuery(sql, "cmd_time_top_handle", tempData, data, 1);
}

public cmd_time_top_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "TimeTop - Could not connect to SQL database.  [%d] %s", errorCode, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "TimeTop - Query failed. [%d] %s", errorCode, error);

		return PLUGIN_CONTINUE;
	}

	new motdData[2048], playerName[MAX_NAME], id = data[0], length = 0, place = 0;

	length = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>")
	length += format(motdData[length], charsmax(motdData) - length, "%8s %24s %15s^n", "Rank", "Nick", "Czas")

	while (SQL_MoreResults(query)) {
		new seconds = SQL_ReadResult(query, 1), minutes = 0, hours = 0;

		SQL_ReadResult(query, 0, playerName, charsmax(playerName));

		replace_all(playerName, charsmax(playerName), "<", "");
		replace_all(playerName, charsmax(playerName), ">", "");

		while (seconds >= 60) {
			seconds -= 60;
			minutes++;

			if (minutes >= 60) {
				minutes -= 60;
				hours++;
			}
		}

		place++;

		length += format(motdData[length], charsmax(motdData) - length, "#%1i%s %-22.22s %3ih %3imin %3is^n", place, place >= 10 ? "" : " ", playerName, hours, minutes, seconds);

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Top15 Czasu Gry");

	return PLUGIN_CONTINUE;
}

public menu_bf1(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new menu = menu_create("\yBF1: \rMenu Glowne", "menu_handler");

	menu_additem(menu, "\wMenu \yPomocy", "0", 0);
	menu_additem(menu, "\wMenu \yStatystyk", "1", 0);
	menu_additem(menu, "\wMenu \yCzasu", "2", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	bf1Player[id][MENU] = MENU_MAIN;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_help(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new menu = menu_create("\yBF1: \rMenu Pomocy", "menu_handler");

	menu_additem(menu, "\wOpis \yModa BF1", "0", 0);
	menu_additem(menu, "\wOpis \yOdznak", "1", 0);
	menu_additem(menu, "\wOpis \yRang", "2", 0);
	menu_additem(menu, "\wOpis \yOrderow^n", "3", 0);
	menu_additem(menu, "\wZmien \yHUD^n", "4", 0);
	menu_additem(menu, "\wWstecz", "5", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	bf1Player[id][MENU] = MENU_HELP;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_stats(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new menu = menu_create("\yBF1: \rMenu Statystyk", "menu_handler");

	menu_additem(menu, "\wPokaz\y Liste Graczy", "0", 0);
	menu_additem(menu, "\wPokaz\y Moje Odznaki i Ordery", "1", 0);
	menu_additem(menu, "\wPokaz\y Moje Statystyki", "2", 0);
	menu_additem(menu, "\wPokaz\y Odznaki i Ordery Gracza", "3", 0);
	menu_additem(menu, "\wPokaz\y Statystyki Gracza", "4", 0);
	menu_additem(menu, "\wPokaz\y Statystyki Serwera^n", "5", 0);
	menu_additem(menu, "\wWstecz", "6", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	bf1Player[id][MENU] = MENU_STATS;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_time(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new menu = menu_create("\yBF1: \rMenu Czasu", "menu_handler");

	menu_additem(menu, "\wPokaz \yMoj Czas", "0", 0);
	menu_additem(menu, "\wPokaz \yListe Stopni", "1", 0);
	menu_additem(menu, "\wPokaz \yTop15 Czasu^n", "2", 0);
	menu_additem(menu, "\wWstecz", "3", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	bf1Player[id][MENU] = MENU_TIME;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_badges(id)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

  	new menu = menu_create("\yBF1: \rInformacje o Odznakach\w", "menu_handler");

	menu_additem(menu, "\wWalka \yNozem", "0", 0);
	menu_additem(menu, "\wWalka \yPistoletem", "1", 0);
	menu_additem(menu, "\wWalka \yBronia Szturmowa", "2", 0);
	menu_additem(menu, "\wWalka \yBronia Snajperska", "3", 0);
	menu_additem(menu, "\wWalka \yBronia Wsparcia", "4", 0);
	menu_additem(menu, "\wWalka \yBronia Wybuchowa", "5", 0);
	menu_additem(menu, "\wWalka \yShotgunem", "6", 0);
	menu_additem(menu, "\wWalka \ySMG", "7", 0);
	menu_additem(menu, "\wWalka \yCzasowa", "8", 0);
	menu_additem(menu, "\wWalka \yOgolna^n", "9", 0);
	menu_additem(menu, "\wWstecz", "10", 0);

	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_BACKNAME, "Wstecz");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	bf1Player[id][MENU] = MENU_BADGES;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_playerlist(id, type)
{
	if (!cvarBf1Enabled) return PLUGIN_CONTINUE;

	new menu = menu_create("\yBF1: \rWybierz Gracza", "menu_handler");

	new playerName[MAX_NAME], playerId[3], players[MAX_PLAYERS], playersNum, player;

	get_players(players, playersNum, "h");

	for (new i = 0; i < playersNum; i++) {
		player = players[i];

		if (is_user_hltv(player) || is_user_bot(player)) continue;

		get_user_name(player, playerName, charsmax(playerName));

		formatex(playerId, charsmax(playerId), "%i", player);

		menu_additem(menu, playerName, playerId, 0);
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu,MPROP_EXITNAME, "Wyjscie");

	bf1Player[id][MENU] = type ? MENU_PLAYERBADGES : MENU_PLAYERSTATS;

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public menu_handler(id, menu, item)
{
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	} else if (item == MENU_BACK) {
		menu_display(id, menu, 0);

		return PLUGIN_HANDLED;
	}

	new data[6], access, callback;

	menu_item_getinfo(menu, item, access, data, charsmax(data), _, _, callback);

	if (!(get_user_flags(id) & access) && access) return PLUGIN_HANDLED;

	new key = str_to_num(data);

	switch (bf1Player[id][MENU]) {
		case MENU_MAIN: {
			switch (key) {
				case 0: menu_help(id);
				case 1:	menu_stats(id);
				case 2:	menu_time(id);
				case 3:	menu_bf1(id);
			}
		} case MENU_HELP: {
			menu_help(id);

			switch (key) {
				case 0: cmd_help(id);
				case 1:	menu_badges(id);
				case 2:	cmd_rank_help(id);
				case 3:	cmd_orders(id);
				case 4:	menu_hud(id);
				case 5: menu_bf1(id);
			}
		} case MENU_STATS: {
			menu_stats(id);

			switch (key) {
				case 0: cmd_ranks(id);
				case 1:	cmd_badges(id, id);
				case 2: cmd_my_stats(id);
				case 3: menu_playerlist(id, 1);
				case 4: menu_playerlist(id, 0);
				case 5: cmd_server_stats(id);
				case 6: menu_bf1(id);
			}
		} case MENU_TIME: {
			menu_time(id);

			switch (key) {
				case 0:	cmd_time(id);
				case 1: cmd_degrees(id);
				case 2: cmd_time_top(id);
				case 3: menu_bf1(id);
			}
		} case MENU_BADGES: {
			menu_badges(id);

			switch (key) {
				case 0 .. 9: cmd_badge_help(id, key + 1);
				case 10: menu_bf1(id);
			}
		} case MENU_PLAYERBADGES: {
			menu_stats(id);

			if (is_user_connected(key)) cmd_badges(id, key);
		} case MENU_PLAYERSTATS: {
			menu_stats(id);

			if (is_user_connected(key)) cmd_stats(id, key);
		}
	}

   	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public sql_init()
{
	new host[64], user[64], pass[64], db[64], queryData[2048], error[128], errorNum;

	get_cvar_string("bf1_sql_host", host, charsmax(host));
	get_cvar_string("bf1_sql_user", user, charsmax(user));
	get_cvar_string("bf1_sql_pass", pass, charsmax(pass));
	get_cvar_string("bf1_sql_db", db, charsmax(db));

	sql = SQL_MakeDbTuple(host, user, pass, db);

	connection = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file(LOG_FILE, "[%s] SQL Error: %s (%d)", PLUGIN, error, errorNum);

		sql = Empty_Handle;

		set_task(5.0, "sql_init");

		return;
	}

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS bf1_server (server VARCHAR(11), rank INT(11), kills INT(11), wins INT(11), rankname VARCHAR(33), killsname VARCHAR(33), winsname VARCHAR(33), PRIMARY KEY (server))");

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS bf1 (name VARCHAR(33), badge1 INT(4), badge2 INT(4), badge3 INT(4), badge4 INT(4), badge5 INT(4), badge6 INT(4), badge7 INT(4), badge8 INT(4), badge9 INT(4), badge10 INT(4), order1 INT(4), order2 INT(4), order3 INT(4), order4 INT(4), order5 INT(4), order6 INT(4), ");
	add(queryData, charsmax(queryData), "order7 INT(4), order8 INT(4), order9 INT(4), order10 INT(4), kills INT(11), hskills INT(11), assists INT(11), gold INT(6), silver INT(6), bronze INT(6), hud INT(4), red INT(4), green INT(4), blue INT(4), posx INT(4), posy INT(4), degree INT(4), admin INT(4), time INT(11) NOT NULL, visits INT(9), ");
	add(queryData, charsmax(queryData), "firstvisit INT(11), lastvisit INT(11), knife INT(9), pistol INT(9), glock INT(9), usp INT(9), p228 INT(9), deagle INT(9), fiveseven INT(9), elites INT(9), sniper INT(9), scout INT(9), awp INT(9), g3sg1 INT(9), sg550 INT(9), rifle INT(9), ak47 INT(9), m4a1 INT(9), galil INT(9), famas INT(9), sg552 INT(9), ");
	add(queryData, charsmax(queryData), "aug INT(9), m249 INT(9), smg INT(9), mac10 INT(9), tmp INT(9), mp5 INT(9), ump45 INT(9), p90 INT(9), grenade INT(9), shotgun INT(9), m3 INT(9), xm1014 INT(9), plants INT(9), explosions INT(9), defuses INT(9), rescues INT(9), survived INT(9), dmgtaken INT(9), dmgreceived INT(9), earned INT(11), PRIMARY KEY (name))");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);

	sqlConnected = true;

	load_server();
}

public load_stats(id)
{
	new queryData[128], data[1];

	data[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM bf1 WHERE name = ^"%s^"", bf1Player[id][SAFE_NAME]);

	SQL_ThreadQuery(sql, "load_stats_handle", queryData, data, 1);
}

public load_server()
	SQL_ThreadQuery(sql, "load_server_handle", "SELECT * FROM bf1_server WHERE server = 'Server'");

public save_stats(id, end)
{
	if (!get_bit(id, loaded) || !sqlConnected) return PLUGIN_CONTINUE;

	new queryData[2048], tempData[512];

	formatex(queryData, charsmax(queryData), "UPDATE bf1 SET badge1 = %i, badge2 = %i, badge3 = %i, badge4 = %i, badge5 = %i, badge6 = %i, badge7 = %i, badge8 = %i, badge9 = %i, badge10 = %i, ",
	bf1Player[id][BADGES][BADGE_KNIFE], bf1Player[id][BADGES][BADGE_PISTOL], bf1Player[id][BADGES][BADGE_ASSAULT], bf1Player[id][BADGES][BADGE_SNIPER], bf1Player[id][BADGES][BADGE_SUPPORT], bf1Player[id][BADGES][BADGE_EXPLOSIVES], bf1Player[id][BADGES][BADGE_SHOTGUN], bf1Player[id][BADGES][BADGE_SMG], bf1Player[id][BADGES][BADGE_GENERAL], bf1Player[id][BADGES][BADGE_TIME]);

	formatex(tempData, charsmax(tempData), "order1 = %i, order2 = %i, order3 = %i, order4 = %i, order5 = %i, order6 = %i, order7 = %i, order8 = %i, order9 = %i, order10 = %i, ",
	bf1Player[id][ORDERS][ORDER_AIMBOT], bf1Player[id][ORDERS][ORDER_ANGEL], bf1Player[id][ORDERS][ORDER_BOMBERMAN], bf1Player[id][ORDERS][ORDER_SAPER], bf1Player[id][ORDERS][ORDER_PERSIST], bf1Player[id][ORDERS][ORDER_DESERV], bf1Player[id][ORDERS][ORDER_MILION], bf1Player[id][ORDERS][ORDER_BULLET], bf1Player[id][ORDERS][ORDER_RAMBO], bf1Player[id][ORDERS][ORDER_SURVIVER]);
	add(queryData, charsmax(queryData), tempData);

	formatex(tempData, charsmax(tempData), "kills = %i, hskills = %i, assists = %i, gold = %i, silver = %i, bronze = %i, hud = %i, red = %i, green = %i, blue = %i, posx = %i, posy = %i, degree = %i, admin = %i, time = %i, visits = %i, lastvisit = %i, knife = %i, pistol = %i, glock = %i, ",
	bf1Player[id][KILLS], bf1Player[id][HS_KILLS], bf1Player[id][ASSISTS], bf1Player[id][GOLD], bf1Player[id][SILVER], bf1Player[id][BRONZE], bf1Player[id][HUD], bf1Player[id][HUD_RED], bf1Player[id][HUD_GREEN], bf1Player[id][HUD_BLUE], bf1Player[id][HUD_POSX], bf1Player[id][HUD_POSY], bf1Player[id][DEGREE], bf1Player[id][ADMIN], bf1Player[id][TIME] + get_user_time(id), bf1Player[id][VISITS], get_systime(), bf1Player[id][KNIFE], bf1Player[id][PISTOL], bf1Player[id][GLOCK]);
	add(queryData, charsmax(queryData), tempData);

	formatex(tempData, charsmax(tempData), "usp = %i, p228 = %i, deagle = %i, fiveseven = %i, elites = %i, sniper = %i, scout = %i, awp = %i, g3sg1 = %i, sg550 = %i, rifle = %i, ak47 = %i, m4a1 = %i, galil = %i, famas = %i, sg552 = %i, aug = %i, m249 = %i, smg = %i, mac10 = %i,",
	bf1Player[id][USP], bf1Player[id][P228], bf1Player[id][DEAGLE], bf1Player[id][FIVESEVEN], bf1Player[id][ELITES], bf1Player[id][SNIPER], bf1Player[id][SCOUT], bf1Player[id][AWP], bf1Player[id][G3SG1], bf1Player[id][SG550], bf1Player[id][RIFLE], bf1Player[id][AK47], bf1Player[id][M4A1], bf1Player[id][GALIL], bf1Player[id][FAMAS], bf1Player[id][SG552], bf1Player[id][AUG], bf1Player[id][M249], bf1Player[id][SMG], bf1Player[id][MAC10]);
	add(queryData, charsmax(queryData), tempData);

	formatex(tempData, charsmax(tempData), "tmp = %i, mp5 = %i, ump45 = %i, p90 = %i, grenade = %i, shotgun = %i, m3 = %i, xm1014 = %i, plants = %i, explosions = %i, defuses = %i, rescues = %i, survived = %i, dmgtaken = %i, dmgreceived = %i, earned = %i WHERE name = ^"%s^"",
	bf1Player[id][TMP], bf1Player[id][MP5], bf1Player[id][UMP45], bf1Player[id][P90], bf1Player[id][GRENADE], bf1Player[id][SHOTGUN], bf1Player[id][M3], bf1Player[id][XM1014], bf1Player[id][PLANTS], bf1Player[id][EXPLOSIONS], bf1Player[id][DEFUSES], bf1Player[id][RESCUES], bf1Player[id][SURVIVED], bf1Player[id][DMG_TAKEN], bf1Player[id][DMG_RECEIVED], bf1Player[id][EARNED], bf1Player[id][SAFE_NAME]);
	add(queryData, charsmax(queryData), tempData);

	switch (end) {
		case NORMAL, DISCONNECT: SQL_ThreadQuery(sql, "query_handle", queryData);
		case MAP_END: query_nonthreaded_handle(queryData);
	}

	if (end) rem_bit(id, loaded);

	return PLUGIN_CONTINUE;
}

public save_server()
{
	if (!sqlConnected || !serverLoaded) return PLUGIN_CONTINUE;

	mysql_escape_string(bf1Server[HIGHESTSERVERRANKNAME], bf1Server[HIGHESTSERVERRANKNAME], charsmax(bf1Server[HIGHESTSERVERRANKNAME]));
	mysql_escape_string(bf1Server[MOSTSERVERKILLSNAME], bf1Server[MOSTSERVERKILLSNAME], charsmax(bf1Server[MOSTSERVERKILLSNAME]));
	mysql_escape_string(bf1Server[MOSTSERVERWINSNAME], bf1Server[MOSTSERVERWINSNAME], charsmax(bf1Server[MOSTSERVERWINSNAME]));

	new queryData[512];

	formatex(queryData, charsmax(queryData), "UPDATE bf1_server SET rank = %i, rankname = '%s', kills = %i, killsname = '%s', wins = %i, winsname = '%s' WHERE server = 'Server'",
	bf1Server[HIGHESTSERVERRANK], bf1Server[HIGHESTSERVERRANKNAME], bf1Server[MOSTSERVERKILLS], bf1Server[MOSTSERVERKILLSNAME], bf1Server[MOSTSERVERWINS], bf1Server[MOSTSERVERWINSNAME]);

	query_nonthreaded_handle(queryData);

	return PLUGIN_CONTINUE;
}

public load_stats_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState) {
		if(failState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Load Server - Could not connect to SQL database.  [%d] %s", errorCode, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Load Server - Query failed. [%d] %s", errorCode, error);

		return PLUGIN_CONTINUE;
	}

	new id = data[0];

	if (!SQL_NumResults(query)) {
		new queryData[256];

		formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO bf1 (name, firstvisit) VALUES('%s', '%i')", bf1Player[id][SAFE_NAME], get_systime());

		SQL_ThreadQuery(sql, "query_handle", queryData);
	} else {
		for (new i = 0; i < MAX_BADGES; i++) bf1Player[id][BADGES][i] = SQL_ReadResult(query, i + 1);
		for (new i = 0; i < MAX_ORDERS; i++) bf1Player[id][ORDERS][i] = SQL_ReadResult(query, i + MAX_BADGES + 1);
		for (new i = 0; i <= EARNED; i++) bf1Player[id][i] = SQL_ReadResult(query, i + MAX_BADGES + MAX_ORDERS + 1);

		bf1Player[id][ADMIN] = (get_user_flags(id) & ADMIN_BAN) ? 1 : 0;

		bf1Player[id][VISITS]++;
	}

	set_bit(id, loaded);

	return PLUGIN_CONTINUE;
}

public load_server_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState) {
		if(failState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Load Server - Could not connect to SQL database.  [%d] %s", errorCode, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Load Server - Query failed. [%d] %s", errorCode, error);

		return PLUGIN_CONTINUE;
	}

	if (!SQL_NumResults(query)) {
		for (new i = 0; i < HIGHESTSERVERRANKNAME; i++) bf1Server[i] = 0;

		formatex(bf1Server[HIGHESTSERVERRANKNAME], charsmax(bf1Server[HIGHESTSERVERRANKNAME]), "Brak");
		formatex(bf1Server[MOSTSERVERKILLSNAME], charsmax(bf1Server[MOSTSERVERKILLSNAME]), "Brak");
		formatex(bf1Server[MOSTWINSNAME], charsmax(bf1Server[MOSTWINSNAME]), "Brak");

		SQL_ThreadQuery(sql, "query_handle", "INSERT IGNORE INTO bf1_server VALUES('Server', '0', '0', '0', 'Brak', 'Brak', 'Brak')");
	} else {
		for (new i = 0; i < HIGHESTSERVERRANKNAME; i++) bf1Server[i] = SQL_ReadResult(query, i + 1);

		SQL_ReadResult(query, 4, bf1Server[HIGHESTSERVERRANKNAME], charsmax(bf1Server[HIGHESTSERVERRANKNAME]));
		SQL_ReadResult(query, 5, bf1Server[MOSTSERVERKILLSNAME], charsmax(bf1Server[MOSTSERVERKILLSNAME]));
		SQL_ReadResult(query, 6, bf1Server[MOSTSERVERWINSNAME], charsmax(bf1Server[MOSTSERVERWINSNAME]));
	}

	serverLoaded = true;

	return PLUGIN_CONTINUE;
}

public query_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState) {
		if(failState == TQUERY_CONNECT_FAILED) log_to_file(LOG_FILE, "Save - Could not connect to SQL database.  [%d] %s", errorCode, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file(LOG_FILE, "Save - Query failed. [%d] %s", errorCode, error);
	}

	return PLUGIN_CONTINUE;
}

public query_nonthreaded_handle(queryData[])
{
	new error[128], errorCode, Handle:query;

	query = SQL_PrepareQuery(connection, queryData);

	if (!SQL_Execute(query)) {
		errorCode = SQL_QueryError(query, error, charsmax(error));

		log_to_file(LOG_FILE, "Save Nonthreaded failed. [%d] %s", errorCode, error);

		SQL_FreeHandle(query);
		SQL_FreeHandle(connection);

		return PLUGIN_CONTINUE;
	}

	SQL_FreeHandle(query);

	return PLUGIN_CONTINUE;
}

public player_glow(id, red, green, blue)
{
	fm_set_rendering(id, kRenderFxGlowShell, red, green, blue, kRenderNormal, 16);

	set_task(1.0, "player_noglow", id + TASK_GLOW);
}

public player_noglow(id)
{
	id -= TASK_GLOW;

	if (!is_user_connected(id)) return;

	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 16);

	if (get_user_weapon(id) == CSW_KNIFE) set_render(id);
}

stock create_icon(id, entity, offset, sprite, life)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(entity);
	write_coord(offset);
	write_short(sprite);
	write_short(life);
	message_end();
}

public screen_flash(id, red, green, blue, alpha)
{
	static gmsgScreenFade;

	if (!gmsgScreenFade) gmsgScreenFade = get_user_msgid("ScreenFade");

	message_begin(MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id);
	write_short(1<<12);
	write_short(1<<12);
	write_short(1<<12);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
}

stock cmd_execute(id, const text[], any:...)
{
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(text) + 2);
	write_byte(10);
	write_string(text);
	message_end();

	#pragma unused text

	new message[256];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}

stock mysql_escape_string(const source[], dest[], length)
{
	copy(dest, length, source);

	replace_all(dest, length, "\\", "\\\\");
	replace_all(dest, length, "\", "\\");
	replace_all(dest, length, "\0", "\\0");
	replace_all(dest, length, "\n", "\\n");
	replace_all(dest, length, "\r", "\\r");
	replace_all(dest, length, "\x1a", "\Z");
	replace_all(dest, length, "'", "\'");
	replace_all(dest, length, "`", "\`");
	replace_all(dest, length, "^"", "\^"");
}

stock Float:distance_to_floor(Float:start[3], ignoreMonsters = 1)
{
	new Float:dest[3], Float:end[3];

	dest[0] = start[0];
	dest[1] = start[1];
	dest[2] = -8191.0;

	engfunc(EngFunc_TraceLine, start, dest, ignoreMonsters, 0, 0);
	get_tr2(0, TR_vecEndPos, end);

	new Float:ret = start[2] - end[2];

	return ret > 0 ? ret : 0.0;
}

stock ham_strip_weapon(id, weaponName[])
{
	if (!equal(weaponName, "weapon_", 7)) return 0;

	new ent, weapon = get_weaponid(weaponName);

	if (!weapon) return 0;

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", weaponName)) && pev(ent, pev_owner) != id) {}

	if (!ent) return 0;

	if (get_user_weapon(id) == weapon) ExecuteHamB(Ham_Weapon_RetireWeapon, ent);

	if (!ExecuteHamB(Ham_RemovplayerInfoItem, id, ent)) return 0;

	ExecuteHamB(Ham_Item_Kill, ent);

	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<weapon));

	return 1;
}

stock bool:check_weapons(id)
{
	new weaponName[32], playersNum, weapon, disallowed[] = {
		CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL,CSW_AK47, CSW_M4A1, CSW_AWP, CSW_SG550,
		CSW_G3SG1, CSW_UMP45,CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

	weapon = get_user_weapons(id, weaponName, playersNum);

	for (new i = 0; i < sizeof(disallowed); i++) {
		if (weapon & (1<<disallowed[i])) return true;
	}

	return false;
}

stock check_map()
{
	new mapName[64];

	get_mapname(mapName, charsmax(mapName));

	new const blockPackagesMaps[][] = {
		"awp_",
		"awp4one",
		"35hp_2"
	};

	if (cvarPackagesEnabled < 2) {
		for (new i = 0; i < sizeof(blockPackagesMaps); i++) {
			if (containi(mapName, blockPackagesMaps[i]) != -1) {
				blockPackages = true;

				break;
			}
		}
	}

	new const blockPowersMaps[][] = {
		"fy_",
		"aim_",
		"mini_",
		"_mini",
		"_long",
		"2x2"
	};

	if (cvarBadgePowers < 2) {
		for (new i = 0; i < sizeof(blockPowersMaps); i++) {
			if (containi(mapName, blockPowersMaps[i]) != -1) {
				blockPowers = true;

				break;
			}
		}
	}
}

public _bf1_get_maxbadges(plugin, params)
	return MAX_BADGES;

public _bf1_get_user_badge(plugin, params)
{
	if (!is_user_connected(get_param(1))) return -1;

	return bf1Player[get_param(1)][BADGES][get_param(2)];
}

public _bf1_get_badge_name(badge, level, data[], length)
{
	param_convert(3);

	copy(data, length, bf1BadgeName[badge][level]);

	return;
}

public _bf1_set_user_badge(plugin, params)
{
	if (!is_user_connected(get_param(1))) return -1;

	return bf1Player[get_param(1)][BADGES][get_param(2)] = get_param(3);
}