#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>
#include <bf1>

#define PLUGIN "Battlefield One VIP"
#define VERSION "2.2"
#define AUTHOR "O'Zone"

#define VIP_FLAG ADMIN_LEVEL_H

new Array:listVIPs, vip, usedMenu, smallMaps, freeVip, freeFrom, freeTo, round = 0, bool:disabled;

new const commandVip[][]= { "say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };

new const primaryWeapons = (1<<CSW_XM1014) | (1<<CSW_MAC10) | (1<<CSW_AUG) | (1<<CSW_M249) | (1<<CSW_GALIL) | (1<<CSW_AK47) | (1<<CSW_M4A1) | (1<<CSW_AWP) | (1<<CSW_SG550) | (1<<CSW_G3SG1) | (1<<CSW_UMP45) | (1<<CSW_MP5NAVY) | (1<<CSW_FAMAS) | (1<<CSW_SG552) | (1<<CSW_TMP) | (1<<CSW_P90) | (1<<CSW_M3);

enum _:{ FREE_HOURS, FREE_ALWAYS };

forward amxbans_admin_connect(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(register_cvar("bf1_vip_small_maps", "0"), smallMaps);
	bind_pcvar_num(register_cvar("bf1_vip_free", "0"), freeVip);
	bind_pcvar_num(register_cvar("bf1_vip_free_from", "23"), freeFrom);
	bind_pcvar_num(register_cvar("bf1_vip_free_to", "09"), freeTo);

	for(new i; i < sizeof commandVip; i++) register_clcmd(commandVip[i], "show_vips");

	register_clcmd("say /vip", "show_vip_motd");

	RegisterHam(Ham_Spawn, "player", "player_spawned", 1);

	register_logevent("game_commencing", 2, "1=Game_Commencing");

	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	register_event("DeathMsg", "death_msg", "a");

	register_message(get_user_msgid("SayText"), "say_text");
	register_message(get_user_msgid("ScoreAttrib"), "vip_status");

	listVIPs = ArrayCreate(64, 32);
}

public plugin_cfg()
	if (!smallMaps) check_map();

public plugin_natives()
	register_native("bf1_get_user_vip", "_get_user_vip", 1);

public plugin_end()
	ArrayDestroy(listVIPs);

public amxbans_admin_connect(id)
	client_authorized_post(id);

public client_authorized(id)
	client_authorized_post(id);

public client_authorized_post(id)
{
	new currentTime[3], hour;

	get_time("%H", currentTime, charsmax(currentTime));

	hour = str_to_num(currentTime);

	if (get_user_flags(id) & VIP_FLAG || freeVip == FREE_ALWAYS || (freeVip == FREE_HOURS && (hour >= get_pcvar_num(freeFrom) || hour < get_pcvar_num(freeTo)))) {
		new playerName[MAX_PLAYERS], tempName[MAX_PLAYERS], listSize = ArraySize(listVIPs);

		get_user_name(id, playerName, charsmax(playerName));

		set_bit(id, vip);

		for (new i = 0; i < listSize; i++) {
			ArrayGetString(listVIPs, i, tempName, charsmax(tempName));

			if (equal(playerName, tempName)) return PLUGIN_CONTINUE;
		}

		ArrayPushString(listVIPs, playerName);
	} else {
		remove_vip(id);
	}

	return PLUGIN_CONTINUE;
}

public remove_vip(id)
{
	if (get_bit(id, vip)) {
		rem_bit(id, vip);

		new name[MAX_NAME], tempName[MAX_NAME], size = ArraySize(listVIPs);

		get_user_name(id, name,charsmax(name));

		for (new i = 0; i < size; i++) {
			ArrayGetString(listVIPs, i, tempName, charsmax(tempName));

			if (equal(tempName, name)) {
				ArrayDeleteItem(listVIPs, i);

				break;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
	remove_vip(id);

public client_infochanged(id)
{
	if (get_bit(id, vip)) {
		new name[MAX_NAME], oldName[MAX_NAME];

		get_user_info(id, "name", name, charsmax(name));
		get_user_name(id, oldName, charsmax(oldName));

		if (!equal(name, oldName)) {
			ArrayPushString(listVIPs, name);

			new tempName[MAX_NAME], size = ArraySize(listVIPs);

			for (new i = 0; i < size; i++) {
				ArrayGetString(listVIPs, i, tempName, charsmax(tempName));

				if (equal(tempName, oldName)) {
					ArrayDeleteItem(listVIPs, i);

					break;
				}
			}
		}
	}
}

public show_vip_motd(id)
	show_motd(id, "vip.txt", "Informacje o VIPie");

public new_round()
	++round;

public game_commencing()
	round = 0;

public player_spawned(id)
{
	if (!is_user_alive(id) || disabled) return PLUGIN_CONTINUE;

	client_authorized_post(id);

	if (!get_bit(id, vip)) return PLUGIN_CONTINUE;

	if (round >= 3) {
		show_vip_menu(id);

		return PLUGIN_CONTINUE;
	}

	StripWeapons(id, Secondary);

	give_item(id, "weapon_deagle");
	give_item(id, "ammo_50ae");

	new weapon_id = find_ent_by_owner(-1, "weapon_deagle", id);

	if (weapon_id) cs_set_weapon_ammo(weapon_id, 7);

	cs_set_user_bpammo(id, CSW_DEAGLE, 35);

	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
	else give_item(id, "weapon_smokegrenade");

	if (round == 2) {
		give_item(id, "weapon_hegrenade");

		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
	}

	return PLUGIN_CONTINUE;
}

public show_vip_menu(id)
{
	rem_bit(id, usedMenu);

	set_task(15.0, "close_menu", id);

	new menu = menu_create("\wMenu VIPa: \rWybierz Zestaw", "show_vip_menu_handler");

	menu_additem(menu, "\yM4A1 + Deagle");
	menu_additem(menu, "\yAK47 + Deagle");
	menu_additem(menu, "\yAWP");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);
}

public show_vip_menu_handler(id, menu, item)
{
	if (!is_user_alive(id)) return PLUGIN_HANDLED;

	set_bit(id, usedMenu);

	if (item == MENU_EXIT) {
		if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
		else give_item(id, "weapon_smokegrenade");

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: {
			StripWeapons(id, Secondary);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			cs_set_user_bpammo(id, CSW_DEAGLE, 35);

			StripWeapons(id, Primary);

			give_item(id, "weapon_m4a1");
			give_item(id, "ammo_556nato");

			cs_set_user_bpammo(id, CSW_M4A1, 90);

			cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);

			client_print(id, print_center, "Dostales M4A1 + Deagle!");
		} case 1: {
			StripWeapons(id, Secondary);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			cs_set_user_bpammo(id, CSW_DEAGLE, 35);

			StripWeapons(id, Primary);

			give_item(id, "weapon_ak47");
			give_item(id, "ammo_762nato");

			cs_set_user_bpammo(id, CSW_AK47, 90);

			cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);

			client_print(id, print_center, "Dostales AK47 + Deagle!");
		} case 2: {
			StripWeapons(id, Primary);

			give_item(id, "weapon_awp");
			give_item(id, "ammo_338magnum");

			cs_set_user_bpammo(id, CSW_AWP, 30);

			client_print(id, print_center, "Dostales AWP!");
		}
	}

	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
	else give_item(id, "weapon_smokegrenade");

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public close_menu(id)
{
	if (!get_bit(id, usedMenu) || !is_user_alive(id)) return PLUGIN_CONTINUE;

	show_menu(id, 0, "^n", 1);

	if (!check_weapons(id)) {
		client_print_color(id, id, "^x04[VIP]^x01 Zestaw zostal ci przydzielony losowo.");

		switch(random_num(0, 2)) {
			case 0: {
				StripWeapons(id, Secondary);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				cs_set_user_bpammo(id, CSW_DEAGLE, 35);

				StripWeapons(id, Primary);

				give_item(id, "weapon_m4a1");
				give_item(id, "ammo_556nato");

				cs_set_user_bpammo(id, CSW_M4A1, 90);

				cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);

				client_print(id, print_center, "Dostales M4A1 + Deagle!");
			} case 1: {
				StripWeapons(id, Secondary);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				cs_set_user_bpammo(id, CSW_DEAGLE, 35);

				StripWeapons(id, Primary);

				give_item(id, "weapon_ak47");
				give_item(id, "ammo_762nato");

				cs_set_user_bpammo(id, CSW_AK47, 90);

				cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);

				client_print(id, print_center, "Dostales AK47 + Deagle!");

				cs_set_user_defuse(id, 1);
			} case 2: {
				StripWeapons(id, Primary);

				give_item(id, "weapon_awp");
				give_item(id, "ammo_338magnum");

				cs_set_user_bpammo(id, CSW_AWP, 30);

				client_print(id, print_center, "Dostales AWP!");
			}
		}
	}

	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);
	else give_item(id, "weapon_smokegrenade");

	return PLUGIN_CONTINUE;
}

public death_msg()
{
	new killer = read_data(1), victim = read_data(2), hs = read_data(3);

	if (!get_bit(killer, vip) || !is_user_alive(killer) || get_user_team(killer) == get_user_team(victim)) return;

	if (hs) {
		set_dhudmessage(38, 218, 116, 0.50, 0.35, 0, 0.0, 1.0, 0.0, 0.0);
		show_dhudmessage(killer, "HeadShot! +15 HP");

		set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) + 15 : min(get_user_health(killer) + 15, 100));

		cs_set_user_money(killer, cs_get_user_money(killer) + 350);
	} else {
		set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
		show_dhudmessage(killer, "Zabiles! +10 HP");

		set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) + 10 : min(get_user_health(killer) + 10, 100));

		cs_set_user_money(killer, cs_get_user_money(killer) + 200);
	}
}

public show_vips(id)
{
	new listName[MAX_NAME], tempMessage[192], chatMessage[192], listSize = ArraySize(listVIPs);

	for (new i = 0; i < listSize; i++) {
		ArrayGetString(listVIPs, i, listName, charsmax(listName));

		add(tempMessage, charsmax(tempMessage), listName);

		if (i == listSize - 1) add(tempMessage, charsmax(tempMessage), ".");
		else add(tempMessage, charsmax(tempMessage), ", ");
	}

	formatex(chatMessage, charsmax(chatMessage), "^x04%s", tempMessage);

	client_print_color(id, id, chatMessage);

	return PLUGIN_CONTINUE;
}

public vip_status()
{
	new id = get_msg_arg_int(1);

	if (is_user_alive(id) && get_bit(id, vip)) {
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | 4);
	}
}

public say_text(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);

	if (is_user_connected(id) && get_bit(id, vip)) {
		new tempMessage[192], message[192], chatPrefix[16], playerName[MAX_PLAYERS];

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

		formatex(chatPrefix, charsmax(chatPrefix), "^x04[VIP]");

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
	}

	return PLUGIN_CONTINUE;
}

stock check_map()
{
	new blockedMapPrefix[][] = {
		"aim_",
		"awp_",
		"awp4one",
		"fy_" ,
		"cs_deagle5" ,
		"fun_allinone",
		"1hp_he"
	}

	new mapName[64];

	get_mapname(mapName, charsmax(mapName));

	for (new i = 0; i < sizeof(blockedMapPrefix); i++) {
		if (containi(mapName, blockedMapPrefix[i]) != -1) {
			disabled = true;
		}
	}
}

stock bool:check_weapons(id)
{
	new playerWeapons[32], weaponsNum;

	get_user_weapons(id, playerWeapons, weaponsNum);

	for (new i = 0; i < weaponsNum; i++) {
		if (primaryWeapons & (1<<playerWeapons[i])) return true;
	}

	return false;
}

public _get_user_vip(id)
	return get_bit(id, vip);
