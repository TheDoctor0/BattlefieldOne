#include <amxmodx>
#include <shop_sms>
#include <bf1>

#define PLUGIN "SklepSMS: Usluga BF1 Odznaki"
#if !defined VERSION
#define VERSION "2.0"
#endif
#define AUTHOR "O'Zone"

#define TASK_MENU 8932

new userData[MAX_PLAYERS + 1], userPage[MAX_PLAYERS + 1], bool:userSelected[MAX_PLAYERS + 1];

new const serviceId[MAX_ID] = "bf1_badge";

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
	ss_register_service(serviceId);

public plugin_natives()
	set_native_filter("native_filter");

public ss_service_chosen(id, amount)
{
	new badgeName[64], menuData[2], menu = menu_create("\yWybierz \rOdznake\w:", "menu_handle"), callback = menu_makecallback("menu_callback");

	for (new i = 0; i < bf1_get_maxbadges(); ++i) {
		bf1_get_badge_name(i, amount, badgeName, charsmax(badgeName));

		menuData[0] = i + 1;
		menuData[1] = bf1_get_user_badge(id,i) >= amount ? 0 : 1;

		menu_additem(menu, badgeName, menuData, 0, callback);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");

	userSelected[id] = false;
	userPage[id] = 0;

	menuData[0] = id;
	menuData[1] = menu;

	display_menu(menuData);

	return SS_STOP;
}

public menu_callback(id, menu, item)
{
	new menuData[3], access, callback;

	menu_item_getinfo(menu, item, access, menuData, charsmax(menuData), _, _, callback);

	return menuData[1] ? ITEM_ENABLED : ITEM_DISABLED;
}

public display_menu(data[])
{
	new id = data[0], menu = data[1];

	if (!is_user_connected(id)) {
		menu_destroy(menu);

		return;
	}

	if (!userSelected[id]) {
		new menu, newmenu, page;

		player_menu_info(id, menu, newmenu, page);

		if (newmenu != menu) menu_display(id, menu, userPage[id]);
		else userPage[id] = page;

		set_task(0.1, "display_menu", TASK_MENU + id, data, 2);
	}
}

public menu_handle(id, menu, item)
{
	if (item == MENU_EXIT) {
		userSelected[id] = true;

		menu_destroy(menu);

		return;
	}

	if (item >= 0) {
		userSelected[id] = true;

		new menuData[2], access, callback;

		menu_item_getinfo(menu, item, access, menuData, charsmax(menuData), _, _, callback);

		userData[id] = menuData[0] - 1;

		menu_destroy(menu);

		ss_show_sms_info(id);
	}
}

public ss_service_bought(id, amount)
{
	new badge_id = userData[id], badge_level = amount;

	if (bf1_set_user_badge(id, badge_id, badge_level) == -1) return SS_ERROR;

	new motdData[512];

	bf1_get_badge_name(badge_id, badge_level, motdData, sizeof motdData);

	format(motdData, sizeof motdData,"<html><body style=^"background-color: #0f0f0f; color: #ccc; font-size: 14px;^"><center><br /><br />\
						<h1>Kupiles/as odznake: <span style=^"color: red^">%s</span><br /><br />\
						W razie problemow skontaktuj sie z nami.\
						</center></body></html>", motdData);

	show_motd(id, motdData, "Informacje dotyczace uslugi");

	return SS_OK;
}

public native_filter(const native_name[], index, trap)
{
	if (trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR);

		pause_plugin();

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
