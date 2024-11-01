
#pragma tabsize 0
#include <a_samp>
#include <a_mysql>
#include <zcmd>
#include <sscanf2>
#include <whirlpool>

#include "../include/gl_common.inc"

#undef	MAX_PLAYERS
#define MAX_PLAYERS 50
#define VEHICLE_REPAIR_COST 2000
#define HEALTH_REPAIR_COST 10000
#define ARMOR_REPAIR_COST 10000

#define MYSQL_HOST "localhost"
#define MYSQL_USER "root"
#define MYSQL_PASS "Randomly97."
#define MYSQL_NAME "ad"

#define	SECONDS_TO_LOGIN 	30

new MySQL: dbclient;
new g_MysqlRaceCheck[MAX_PLAYERS];

enum {
	DIALOG_UNUSED,
	DIALOG_LOGIN,
	DIALOG_REGISTER,
};

enum Minigame {
	NO_ZONE,
	WWZONE,
	RWZONE,
	AD,
	DUEL,
};

enum PLAYER {
	id,
	ip[17],
	nick[MAX_PLAYER_NAME],
	rank,
	password[65],
	salt[17],
	interior,
	Cache: Cache_ID,
	bool: is_logged_in,
	loggin_attempts,
	login_timer,
	v_timer,
	vehicle_id,
	skin,
	money,
	minigame[Minigame],

	dmg_given_td_timer,
	dmg_received_td_timer,
	Text: DMGGivenTD,
	Text: DMGReceivedTD,
	Float:dmg_given,
	Float:dmg_received,
	dmg_given_to,
	dmg_received_from,

	blocked_pms,
	blocked_goto,
	streak,
};

new Players[MAX_PLAYERS][PLAYER];

#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_SIGNED_OUT 0x9b9b9b
#define COLOR_SUCCESS 0x69ff61AA
#define COLOR_ERROR 0xff4d4fAA
#define COLOR_INFO 0x47a0ffAA
#define COLOR_PM 0xfff700AA

#define COLOR_RANK_1 0xFFFFFFFF

new VehicleNames[212][] = {
	{"Landstalker"},{"Bravura"},{"Buffalo"},{"Linerunner"},{"Perrenial"},{"Sentinel"},{"Dumper"},
	{"Firetruck"},{"Trashmaster"},{"Stretch"},{"Manana"},{"Infernus"},{"Voodoo"},{"Pony"},{"Mule"},
	{"Cheetah"},{"Ambulance"},{"Leviathan"},{"Moonbeam"},{"Esperanto"},{"Taxi"},{"Washington"},
	{"Bobcat"},{"Mr Whoopee"},{"BF Injection"},{"Hunter"},{"Premier"},{"Enforcer"},{"Securicar"},
	{"Banshee"},{"Predator"},{"Bus"},{"Rhino"},{"Barracks"},{"Hotknife"},{"Trailer 1"},{"Previon"},
	{"Coach"},{"Cabbie"},{"Stallion"},{"Rumpo"},{"RC Bandit"},{"Romero"},{"Packer"},{"Monster"},
	{"Admiral"},{"Squalo"},{"Seasparrow"},{"Pizzaboy"},{"Tram"},{"Trailer 2"},{"Turismo"},
	{"Speeder"},{"Reefer"},{"Tropic"},{"Flatbed"},{"Yankee"},{"Caddy"},{"Solair"},{"Berkley's RC Van"},
	{"Skimmer"},{"PCJ-600"},{"Faggio"},{"Freeway"},{"RC Baron"},{"RC Raider"},{"Glendale"},{"Oceanic"},
	{"Sanchez"},{"Sparrow"},{"Patriot"},{"Quad"},{"Coastguard"},{"Dinghy"},{"Hermes"},{"Sabre"},
	{"Rustler"},{"ZR-350"},{"Walton"},{"Regina"},{"Comet"},{"BMX"},{"Burrito"},{"Camper"},{"Marquis"},
	{"Baggage"},{"Dozer"},{"Maverick"},{"News Chopper"},{"Rancher"},{"FBI Rancher"},{"Virgo"},{"Greenwood"},
	{"Jetmax"},{"Hotring"},{"Sandking"},{"Blista Compact"},{"Police Maverick"},{"Boxville"},{"Benson"},
	{"Mesa"},{"RC Goblin"},{"Hotring Racer A"},{"Hotring Racer B"},{"Bloodring Banger"},{"Rancher"},
	{"Super GT"},{"Elegant"},{"Journey"},{"Bike"},{"Mountain Bike"},{"Beagle"},{"Cropdust"},{"Stunt"},
	{"Tanker"}, {"Roadtrain"},{"Nebula"},{"Majestic"},{"Buccaneer"},{"Shamal"},{"Hydra"},{"FCR-900"},
	{"NRG-500"},{"HPV1000"},{"Cement Truck"},{"Tow Truck"},{"Fortune"},{"Cadrona"},{"FBI Truck"},
	{"Willard"},{"Forklift"},{"Tractor"},{"Combine"},{"Feltzer"},{"Remington"},{"Slamvan"},
	{"Blade"},{"Freight"},{"Streak"},{"Vortex"},{"Vincent"},{"Bullet"},{"Clover"},{"Sadler"},
	{"Firetruck LA"},{"Hustler"},{"Intruder"},{"Primo"},{"Cargobob"},{"Tampa"},{"Sunrise"},{"Merit"},
	{"Utility"},{"Nevada"},{"Yosemite"},{"Windsor"},{"Monster A"},{"Monster B"},{"Uranus"},{"Jester"},
	{"Sultan"},{"Stratum"},{"Elegy"},{"Raindance"},{"RC Tiger"},{"Flash"},{"Tahoma"},{"Savanna"},
	{"Bandito"},{"Freight Flat"},{"Streak Carriage"},{"Kart"},{"Mower"},{"Duneride"},{"Sweeper"},
	{"Broadway"},{"Tornado"},{"AT-400"},{"DFT-30"},{"Huntley"},{"Stafford"},{"BF-400"},{"Newsvan"},
	{"Tug"},{"Trailer 3"},{"Emperor"},{"Wayfarer"},{"Euros"},{"Hotdog"},{"Club"},{"Freight Carriage"},
	{"Trailer 3"},{"Andromada"},{"Dodo"},{"RC Cam"},{"Launch"},{"Police Car (LSPD)"},{"Police Car (SFPD)"},
	{"Police Car (LVPD)"},{"Police Ranger"},{"Picador"},{"S.W.A.T. Van"},{"Alpha"},{"Phoenix"},{"Glendale"},
	{"Sadler"},{"Luggage Trailer A"},{"Luggage Trailer B"},{"Stair Trailer"},{"Boxville"},{"Farm Plow"},
	{"Utility Trailer"}
};
new Float:wwZones[][3] = {
	{ -1424.357055, 929.259094, 1036.399169 },
	{ -1443.694824, 931.948486, 1036.491088 },
	{ -1463.177368, 935.461730, 1036.595825 },
	{ -1311.567382, 951.553710, 1036.564941 },
	{ -1283.012695, 1014.890930, 1037.577392 },
	{ -1347.303833, 1053.358520, 1038.324584 },
	{ -1452.426879, 1056.182373, 1038.555786 },
	{ -1516.813964, 1003.334594, 1037.783203 }
};
new Float:spawns[][3] = {
	{ 1614.149414, -1256.707641, 17.504936 },
	{ 1541.425659, -1626.858276, 13.382812 },
	{ 1198.294067, -925.463500, 43.037166 },
	{ 2030.931518, 1917.722412, 12.324687 },
	{ 2162.192626, 2161.357910, 10.820312 },
	{ 2104.294677, 1017.054199, 10.820312 },
	{ -2022.167846, -53.404064, 35.354389 },
	{ -1969.328613, 539.657104, 35.171875 },
	{ -1754.156494, 955.293395, 24.742187 },
	{ 2028.619995, 1544.070922, 10.820312 },
	{ -1969.760986, 294.444641, 35.171875 },
	{ 2490.676513, -1669.673706, 13.335947 }
};
new ArenaOneGateOne;
new ArenaOneGateTwo;
new ArenaTwoGateOne;
new ArenaTwoGateTwo;


enum DUEL_ARENA {
	bool:is_occupied,
	challenger_id,
	challenged_id,
	weapons[3],
	countdown,
};

new Float:DuelArenaOneSpawns[2][3] = {
	{ 2645.735107, 1189.662841, 26.918153 },
	{ 2644.699951, 1232.247192, 26.918153 },
};

new Float:DuelArenaTwoSpawns[2][3] = {
	{ 1901.247070, 1374.817504, 24.718750 },
	{ 1898.018798, 1316.022460, 24.718750 },
};

new DuelArenas[2][DUEL_ARENA];

#if defined FILTERSCRIPT

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Blank Filterscript by your name here");
	print("--------------------------------------\n");
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

#else

main()
{
	print("\n----------------------------------");
	print(" Blank Gamemode by your name here");
	print("----------------------------------\n");
}

#endif

public OnGameModeInit()
{
	// #region ARENA 1
	CreateObject(987,2631.7000000,1186.4000000,25.9000000,0.0000000,0.0000000,0.0000000);
	CreateObject(987,2642.8999000,1186.5000000,25.9000000,0.0000000,0.0000000,0.0000000);
	CreateObject(987,2647.6001000,1186.5000000,25.9000000,0.0000000,0.0000000,0.0000000);
	CreateObject(987,2631.5000000,1198.5000000,25.9000000,0.0000000,0.0000000,-90.0000000);
	CreateObject(987,2631.5000000,1209.7000000,25.9000000,0.0000000,0.0000000,-90.0000000);
	CreateObject(987,2631.5000000,1221.2000000,25.9000000,0.0000000,0.0000000,-90.0000000);
	CreateObject(987,2631.3000000,1232.7000000,25.9000000,0.0000000,0.0000000,-90.0000000);
	CreateObject(987,2631.3999000,1235.7000000,25.9000000,0.0000000,0.0000000,-90.0000000);
	CreateObject(987,2659.0000000,1186.6000000,25.9000000,0.0000000,0.0000000,90.3430000);
	CreateObject(987,2659.1001000,1198.3000000,25.9000000,0.0000000,0.0000000,91.2780000);
	CreateObject(987,2659.0000000,1209.8000000,25.9000000,0.0000000,0.0000000,89.4070000);
	CreateObject(987,2659.1001000,1217.7000000,25.9000000,0.0000000,0.0000000,90.3420000);
	CreateObject(987,2658.8999000,1223.7000000,25.9000000,0.0000000,0.0000000,90.3420000);
	CreateObject(987,2631.4004000,1235.7002000,25.9000000,0.0000000,0.0000000,-90.0000000);
	CreateObject(987,2658.8999000,1235.5000000,25.9000000,0.0000000,0.0000000,-179.8290000);
	CreateObject(987,2647.8000000,1235.5000000,25.9000000,0.0000000,0.0000000,-179.8300000);
	CreateObject(987,2643.6001000,1235.4000000,25.9000000,0.0000000,0.0000000,-179.8300000);
	CreateObject(3819,2625.8999000,1224.1000000,26.9000000,0.0000000,0.0000000,-179.6570000);
	CreateObject(3819,2625.8999000,1215.6000000,26.9000000,0.0000000,0.0000000,-179.6590000);
	CreateObject(3819,2626.0000000,1207.0000000,26.9000000,0.0000000,0.0000000,-179.6590000);
	CreateObject(3819,2626.1001000,1198.5000000,26.9000000,0.0000000,0.0000000,-179.6590000);
	CreateObject(3819,2664.2000000,1223.0000000,26.9000000,0.0000000,0.0000000,-0.9380000);
	CreateObject(3819,2664.1001000,1214.3000000,26.9000000,0.0000000,0.0000000,-0.9390000);
	CreateObject(3819,2663.8999000,1205.9000000,26.9000000,0.0000000,0.0000000,-0.9390000);
	CreateObject(3819,2663.8999000,1197.3000000,26.9000000,0.0000000,0.0000000,-0.9390000);
	CreateObject(1337,-1940.7794200,385.3542800,35.8946200,0.0000000,0.0000000,0.0000000);
	CreateObject(971,2650.5000000,1191.1000000,29.5000000,0.0000000,0.0000000,90.6720000);
	CreateObject(971,2642.0000000,1190.9000000,29.5000000,0.0000000,0.0000000,-88.8010000);
	CreateObject(971,2649.3000000,1231.0000000,29.5000000,0.0000000,0.0000000,90.6720000);
	CreateObject(971,2640.5000000,1230.9000000,29.5000000,0.0000000,0.0000000,90.1700000);
	ArenaOneGateOne = CreateObject(971,2646.2998000,1195.2002000,29.5000000,0.0000000,0.0000000,0.4280000);
	ArenaOneGateTwo = CreateObject(971,2644.8999000,1226.6000000,29.5000000,0.0000000,0.0000000,0.0000000);
	// 2645.735107, 1189.662841, 26.918153
	// 2644.699951, 1232.247192, 26.918153
	// #endregion

	// #region ARENA 2
	CreateObject(985,1912.8000000,1377.5000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1885.3323000,1377.4399000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1893.2000000,1377.5000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1901.0000000,1377.5000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1908.8000000,1377.5000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1885.4000000,1313.2000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1893.3000000,1313.2000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1901.2000000,1313.2000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1908.9000000,1313.2000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1912.8000000,1313.2000000,25.4000000,0.0000000,0.0000000,0.0000000);
	CreateObject(985,1916.7000000,1317.0000000,25.4000000,0.0000000,0.0000000,89.8290000);
	CreateObject(985,1916.7000000,1324.9000000,25.4000000,0.0030000,-0.9360000,89.8240000);
	CreateObject(985,1916.7000000,1332.7000000,25.4000000,0.0000000,-0.9390000,89.8240000);
	CreateObject(985,1916.6000000,1340.5000000,25.4000000,0.0000000,-0.9390000,89.8240000);
	CreateObject(985,1916.6000000,1348.4000000,25.4000000,0.0000000,-0.9390000,89.8240000);
	CreateObject(985,1916.6000000,1356.3000000,25.4000000,0.0000000,-0.9390000,89.8240000);
	CreateObject(985,1916.7000000,1364.1000000,25.4000000,0.0000000,-0.9390000,89.8240000);
	CreateObject(985,1916.7000000,1371.8000000,25.4000000,0.0000000,-0.9390000,89.8240000);
	CreateObject(985,1916.6000000,1373.6000000,25.4000000,0.0000000,-0.9390000,87.9530000);
	CreateObject(985,1881.4000000,1373.6000000,25.4000000,0.0000000,-0.9450000,89.8220000);
	CreateObject(985,1881.4000000,1365.6000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1881.4000000,1357.8000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1881.4000000,1349.9000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1881.4000000,1342.1000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1881.5000000,1334.3000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1881.5000000,1326.5000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1881.6000000,1318.7000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1881.4000000,1317.1000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1901.8000000,1317.1000000,25.4000000,0.0000000,0.0000000,89.8240000);
	CreateObject(985,1894.0000000,1317.0000000,25.4000000,0.0000000,0.0000000,89.8240000);
	CreateObject(985,1897.1000000,1373.5000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	CreateObject(985,1905.1000000,1373.5000000,25.4000000,0.0000000,-0.9450000,89.8190000);
	ArenaTwoGateOne = CreateObject(985,1897.9000000,1321.0000000,25.4000000,0.0000000,0.0000000,0.0000000);
	ArenaTwoGateTwo = CreateObject(985,1901.1000000,1369.6000000,25.4000000,0.0000000,0.0000000,0.0000000);
	// 1901.247070, 1374.817504, 24.718750
	// 1898.018798, 1316.022460, 24.718750
	// #endregion

	new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	dbclient = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_NAME, option_id);
	UsePlayerPedAnims();
	if (dbclient == MYSQL_INVALID_HANDLE || mysql_errno(dbclient) != 0) {
		new db_err_message[128];
		format(db_err_message, sizeof(db_err_message), "[DB] Error connecting to database: %i", mysql_errno(dbclient));
		print(db_err_message);
		SendRconCommand("exit");
	} else {
		print("[DB] Connected to database successfully");
	}
	SetGameModeText("FR/DM/AD");
	resetArenas();
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
	return 1;
}

public OnPlayerConnect(playerid)
{
	SetPlayerColor(playerid, COLOR_SIGNED_OUT);
	g_MysqlRaceCheck[playerid]++;

	static const empty_player[PLAYER];
	Players[playerid] = empty_player;

	Players[playerid][DMGGivenTD] = TextDrawCreate(481.000000, 395.000000, "");
	TextDrawFont(Players[playerid][DMGGivenTD], 1);
	TextDrawLetterSize(Players[playerid][DMGGivenTD], 0.170833, 0.800000);
	TextDrawTextSize(Players[playerid][DMGGivenTD], 613.000000, 20.000000);
	TextDrawSetOutline(Players[playerid][DMGGivenTD], 1);
	TextDrawSetShadow(Players[playerid][DMGGivenTD], 0);
	TextDrawAlignment(Players[playerid][DMGGivenTD], 1);
	TextDrawColor(Players[playerid][DMGGivenTD], 16711935);
	TextDrawBackgroundColor(Players[playerid][DMGGivenTD], 255);
	TextDrawBoxColor(Players[playerid][DMGGivenTD], 0);
	TextDrawUseBox(Players[playerid][DMGGivenTD], 1);
	TextDrawSetProportional(Players[playerid][DMGGivenTD], 1);
	TextDrawSetSelectable(Players[playerid][DMGGivenTD], 0);

	Players[playerid][DMGReceivedTD] = TextDrawCreate(481.000000, 405.000000, "");
	TextDrawFont(Players[playerid][DMGReceivedTD], 1);
	TextDrawLetterSize(Players[playerid][DMGReceivedTD], 0.170833, 0.800000);
	TextDrawTextSize(Players[playerid][DMGReceivedTD], 613.000000, 20.000000);
	TextDrawSetOutline(Players[playerid][DMGReceivedTD], 1);
	TextDrawSetShadow(Players[playerid][DMGReceivedTD], 0);
	TextDrawAlignment(Players[playerid][DMGReceivedTD], 1);
	TextDrawColor(Players[playerid][DMGReceivedTD], COLOR_ERROR);
	TextDrawBackgroundColor(Players[playerid][DMGReceivedTD], 255);
	TextDrawBoxColor(Players[playerid][DMGReceivedTD], 0);
	TextDrawUseBox(Players[playerid][DMGReceivedTD], 1);
	TextDrawSetProportional(Players[playerid][DMGReceivedTD], 1);
	TextDrawSetSelectable(Players[playerid][DMGReceivedTD], 0);

	GetPlayerName(playerid, Players[playerid][nick], MAX_PLAYER_NAME);
	GetPlayerIp(playerid, Players[playerid][ip], 16);

	new query[103];
	mysql_format(dbclient, query, sizeof query, "SELECT * FROM `users` WHERE `nick` = '%e' LIMIT 1", Players[playerid][nick]);
	print(query);
	mysql_tquery(dbclient, query, "OnCheckSessionLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);
	return 1;
}

public OnPlayerDisconnect(playerid, reason) {
	new query[500];
	mysql_format(dbclient, query, sizeof query, "UPDATE users SET money = %d WHERE id = %d;", GetPlayerMoney(playerid), Players[playerid][id]);
	print(query);
	mysql_tquery(dbclient, query);
	if(Players[playerid][vehicle_id] != 0) {
		DestroyVehicle(Players[playerid][vehicle_id]);
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	Players[playerid][streak] = 0;
	if (Players[playerid][minigame] == NO_ZONE) {
		SpawnPlayerInNoZone(playerid);
	} else if (Players[playerid][minigame] == WWZONE) {
		SpawnPlayerInWwZone(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	SendDeathMessage(killerid, playerid, reason);
	Players[playerid][streak]++;

	if (Players[killerid][minigame] == WWZONE) {
		SetPlayerHealth(killerid, 100.0);
		SetPlayerArmour(killerid, 100.0);
	}
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart) {
	if (issuerid != INVALID_PLAYER_ID) {
		new dmgGivenMessage[255], dmgReceivedMessage[255], receiverName[100], issuerName[100], weaponName[100], Float: receiverHealth, Float: x, Float: y, Float: z;

		GetPlayerHealth(playerid, receiverHealth);
		GetPlayerPos(playerid, x, y, z);
		new Float:distance = GetPlayerDistanceFromPoint(issuerid, x, y, z);
	
		PlayerPlaySound(playerid, 1131, 0, 0, 0);
		PlayerPlaySound(issuerid, 17802, 0, 0, 0);

		if (Players[playerid][dmg_received_from] != issuerid) {
			Players[playerid][dmg_received] = 0;
		}
		Players[playerid][dmg_received_from] = issuerid;

		
		if (Players[issuerid][dmg_given_to] != playerid) {
			Players[issuerid][dmg_given] = 0;
		}
		Players[issuerid][dmg_given_to] = playerid;

		new Float:calculatedReceivedAmmount = amount + Players[playerid][dmg_received];
		new Float:calculatedGivenAmount = amount + Players[issuerid][dmg_given];
		if ((receiverHealth) < amount) {
			calculatedReceivedAmmount = Players[playerid][dmg_received] + receiverHealth + 1;
			calculatedGivenAmount = Players[issuerid][dmg_given] + receiverHealth + 1;
		}
		
		Players[playerid][dmg_received] = calculatedReceivedAmmount;
		Players[issuerid][dmg_given] = calculatedGivenAmount;

		GetPlayerName(issuerid, issuerName, sizeof issuerName);
		GetPlayerName(playerid, receiverName, sizeof receiverName);
		GetWeaponName(weaponid, weaponName, sizeof(weaponName));
		
		format(dmgReceivedMessage, sizeof(dmgReceivedMessage), "-%.0fHP de %s (%s) a %.0fm", calculatedReceivedAmmount, issuerName, weaponName, distance);
		showDmgReceivedTdForPlayer(playerid, dmgReceivedMessage);

		format(dmgGivenMessage, sizeof(dmgGivenMessage), "-%.0fHP a %s (%s) a %.0fm", calculatedGivenAmount, receiverName, weaponName, distance);
		showDmgGivenTdForPlayer(issuerid, dmgGivenMessage);
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch (dialogid) {
		case DIALOG_UNUSED: return 1;

		case DIALOG_REGISTER: {
			if (!response) return Kick(playerid);

			if (strlen(inputtext) <= 5 || strlen(inputtext) > 20) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registro", "Tu contrasena debe cumplir lo siguiente:\n- Mas de 5 caracteres\n- Menor a 20 caracteres\nPorfavor ingresa la contrasena:", "Registrarme", "Cancelar");

			for (new i = 0; i < 16; i++) Players[playerid][salt][i] = random(94) + 33;
			SHA256_PassHash(inputtext, Players[playerid][salt], Players[playerid][password], 65);

			new query[500];
			mysql_format(dbclient, query, sizeof query, "INSERT INTO users (`nick`, `password`, `salt`, `rank`, `is_banned`, `ip`, `is_logged_in`, `interior`) VALUES ('%e', '%e', '%e', 1, 0, '%e', 1, 0);", Players[playerid][nick], Players[playerid][password], Players[playerid][salt], Players[playerid][ip]);
			print(query);
			mysql_tquery(dbclient, query, "OnPlayerRegister", "d", playerid);
		}

		case DIALOG_LOGIN: {
			if (!response) return Kick(playerid);

			new hashed_pass[65];
			SHA256_PassHash(inputtext, Players[playerid][salt], hashed_pass, 65);

			if (strcmp(hashed_pass, Players[playerid][password]) == 0) {
				SetPlayerColor(playerid, COLOR_WHITE);
				SendClientMessage(playerid, COLOR_SUCCESS, "Has ingresado exitosamente.");
				PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
				cache_set_active(Players[playerid][Cache_ID]);
				cache_delete(Players[playerid][Cache_ID]);

				KillTimer(Players[playerid][login_timer]);
				Players[playerid][login_timer] = 0;
				Players[playerid][is_logged_in] = true;
				Players[playerid][blocked_pms] = 0;
				Players[playerid][blocked_goto] = 0;

				SetSpawnInfo(playerid, NO_TEAM, 0, 1958.3783, 1343.1572, 15.3746, 0.0, 0, 0, 0, 0, 0, 0);
				SpawnPlayer(playerid);
				GivePlayerMoney(playerid, Players[playerid][money]);
			} else {
				Players[playerid][loggin_attempts]++;

				if (Players[playerid][loggin_attempts] >= 3) {
					SendClientMessage(playerid, COLOR_ERROR, "Has introducido la contrasena mal repetidas veces (3).");
					DelayedKick(playerid);
				} else {
					ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Contrasena incorrecta!\nIngresa la contrasena correcta:", "Login", "Abort");
				}
			}

		}
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

forward OnCheckSessionLoaded(playerid, race_check);
public OnCheckSessionLoaded(playerid, race_check) {
	print("OnCheckSessionLoaded");
	if (race_check != g_MysqlRaceCheck[playerid]) return Kick(playerid);

	new message[200];
	if(cache_num_rows() > 0) {
		cache_get_value_int(0, "id", Players[playerid][id]);
		cache_get_value(0, "password", Players[playerid][password], 65);
		cache_get_value(0, "salt", Players[playerid][salt], 17);
		cache_get_value_int(0, "skin", Players[playerid][skin]);
		cache_get_value_int(0, "money", Players[playerid][money]);
		Players[playerid][Cache_ID] = cache_save();
		format(message, sizeof message, "Esta cuenta (%s) esta registrada. Ingresa la contrasena:", Players[playerid][nick]);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", message, "Login", "Cancelar");
		Players[playerid][login_timer] = SetTimerEx("OnLoginTimeout", SECONDS_TO_LOGIN * 1000, false, "d", playerid);
	} else {
		format(message, sizeof message, "Bienvenido %s, ingresa tu contrasena para registrarte:", Players[playerid][nick]);
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registro", message, "Registrarme", "Cancelar");
	}
	return 1;
}

forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	Players[playerid][id] = cache_insert_id();

	SendClientMessage(playerid, COLOR_SUCCESS, "Registrado exitosamente!");
	PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);

	Players[playerid][is_logged_in] = true;
	SetSpawnInfo(playerid, NO_TEAM, 0, 1958.3783, 1343.1572, 15.3746, 0.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
	SetPlayerColor(playerid, COLOR_WHITE);
	return 1;
}

DelayedKick(playerid, time = 200)
{
	SetTimerEx("_KickPlayerDelayed", time, false, "d", playerid);
	return 1;
}

forward _KickPlayerDelayed(playerid);
public _KickPlayerDelayed(playerid)
{
	Kick(playerid);
	return 1;
}

forward UpdatePlayerSkin(playerid, skinid);
public UpdatePlayerSkin(playerid, skinid) {
	new query[500];
	mysql_format(dbclient, query, sizeof query, "UPDATE users SET skin = %d WHERE id = %d;", Players[playerid][skin], Players[playerid][id]);
	print(query);
	mysql_tquery(dbclient, query);
}

CMD:skin(playerid, params[]) {
	new skinid, result;
	result = sscanf(params, "n", skinid);
	if (result == 0) {
		if (skinid < 0 || skinid > 312) {
			SendClientMessage(playerid, COLOR_ERROR, "Skin invalido, uso: /skin [skinid]");
			return 1;
		}
		Players[playerid][skin] = skinid;
		SetPlayerSkin(playerid, skinid);
		UpdatePlayerSkin(playerid, skinid);
	} else {
		SendClientMessage(playerid, COLOR_ERROR, "Skin invalido, uso: /skin [skinid]");
	}
	return 1;
}

CMD:dbid(playerid, params[]) {
	printf("MySQL id: %d", Players[playerid][id]);
	return 1;
}

CMD:rw(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	if (IsPlayerInAnyVehicle(playerid)) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando en un vehiculo.");
	} else {
		ResetPlayerWeapons(playerid);
		GivePlayerWeapon(playerid, 26, 9999);
		GivePlayerWeapon(playerid, 28, 9999);
	}
	return 1;
}

CMD:ww(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	if (IsPlayerInAnyVehicle(playerid)) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando en un vehiculo.");
	} else {
		ResetPlayerWeapons(playerid);
		GivePlayerWeapon(playerid, 24, 9999);
		GivePlayerWeapon(playerid, 25, 9999);
		GivePlayerWeapon(playerid, 34, 9999);
	}
	return 1;
}

CMD:ww2(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	if (IsPlayerInAnyVehicle(playerid)) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando en un vehiculo.");
	} else {
		ResetPlayerWeapons(playerid);
		GivePlayerWeapon(playerid, 24, 9999);
		GivePlayerWeapon(playerid, 27, 9999);
		GivePlayerWeapon(playerid, 33, 9999);
	}
	return 1;
}

CMD:pos(playerid, params[]) {
	new Float: x, Float: y, Float: z;
	GetPlayerPos(playerid, x, y, z);
	printf("Player %d's position: %f, %f, %f", playerid, x, y, z);
	return 1;
}

CMD:infernus(playerid, params[]) {
	if (Players[playerid][vehicle_id] != 0) {
		DestroyVehicle(Players[playerid][vehicle_id]);
	}

	new Float: x, Float: y, Float: z, Float: angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);
	new vehicleid = CreateVehicle(411, x, y, z, angle, 0, 0, 0);
	LinkVehicleToInterior(vehicleid, 0);
	SetVehicleToRespawn(vehicleid);
	PutPlayerInVehicle(playerid, vehicleid, 0);
	Players[playerid][vehicle_id] = vehicleid;
	return 1;
}

CMD:hydra(playerid, params[]) {
	if (Players[playerid][vehicle_id] != 0) {
		DestroyVehicle(Players[playerid][vehicle_id]);
	}

	new Float: x, Float: y, Float: z, Float: angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);
	new vehicleid = CreateVehicle(520, x, y, z, angle, 0, 0, 0);
	LinkVehicleToInterior(vehicleid, 0);
	SetVehicleToRespawn(vehicleid);
	PutPlayerInVehicle(playerid, vehicleid, 0);
	Players[playerid][vehicle_id] = vehicleid;
	return 1;
}

CMD:v(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	if (Players[playerid][v_timer] != 0) {
		SendClientMessage(playerid, COLOR_ERROR, "Aun no puedes spawnear otro vehiculo.");
		return 1;
	}
	new vehicleId, param[25], result;
	result = sscanf(params, "s[25]", param);
	vehicleId = GetVehicleModelIDFromName(param);
	if (result == -1) {
		SendClientMessage(playerid, COLOR_ERROR, "Nombre de vehiculo invalido, usa: /v [vehicleid]");
		return 1;
	}
	if (vehicleId == 520 || vehicleId == 432 || vehicleId == 476 || vehicleId == 592 || vehicleId == 577 || vehicleId == 425 || vehicleId == 469) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este vehiculo.");
		return 1;
	}

	if (Players[playerid][vehicle_id] != 0) {
		DestroyVehicle(Players[playerid][vehicle_id]);
	}
	new Float: x, Float: y, Float: z, Float: angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);
	new createdVehicle = CreateVehicle(vehicleId, x, y, z, angle, 0, 0, 0);
	LinkVehicleToInterior(createdVehicle, 0);
	SetVehicleToRespawn(createdVehicle);
	PutPlayerInVehicle(playerid, createdVehicle, 0);
	Players[playerid][vehicle_id] = createdVehicle;
	Players[playerid][v_timer] = SetTimerEx("onVTimeout", 3000, false, "d", playerid);
	return 1;
}

CMD:fix(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	if (!IsPlayerInAnyVehicle(playerid)) {
		SendClientMessage(playerid, COLOR_ERROR, "No estas en un vehiculo.");
		return 1;
	}
	new playerMoney = GetPlayerMoney(playerid);

	if (playerMoney < VEHICLE_REPAIR_COST) {
		new message[100];
		format(message, sizeof message, "No tienes suficiente dinero, se necesita $%d.", VEHICLE_REPAIR_COST);
		SendClientMessage(playerid, COLOR_ERROR, message);
		return 1;
	}
	new playerVehicleId = GetPlayerVehicleID(playerid);
	SetVehicleHealth(playerVehicleId, 1000.0);
	RepairVehicle(playerVehicleId);
	GivePlayerMoney(playerid, -VEHICLE_REPAIR_COST);
	SendClientMessage(playerid, COLOR_SUCCESS, "Se ha reparado tu vehiculo.");
	PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
	return 1;
}

CMD:vida(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	new playerMoney = GetPlayerMoney(playerid);
	new message[255];

	if (playerMoney < HEALTH_REPAIR_COST) {
		format(message, sizeof message, "No tienes suficiente dinero, se necesita $%d.", HEALTH_REPAIR_COST);
		SendClientMessage(playerid, COLOR_ERROR, message);
		return 1;
	}

	SetPlayerHealth(playerid, 100.0);
	PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
	GivePlayerMoney(playerid, -HEALTH_REPAIR_COST);
	notifyPlayerAction(playerid, "Se ha subido la vida.");
	return 1;
}

CMD:chaleco(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	new playerMoney = GetPlayerMoney(playerid);
	new message[255];

	if (playerMoney < ARMOR_REPAIR_COST) {
		format(message, sizeof message, "No tienes suficiente dinero, se necesita $%d.", ARMOR_REPAIR_COST);
		SendClientMessage(playerid, COLOR_ERROR, message);
		return 1;
	}

	SetPlayerArmour(playerid, 100.0);
	PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
	GivePlayerMoney(playerid, -ARMOR_REPAIR_COST);
	notifyPlayerAction(playerid, "Se ha subido el chaleco.");
	return 1;
}

CMD:kill(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	SetPlayerHealth(playerid, 0.0);
	return 1;
}

CMD:salir(playerid, params[]) {
	Players[playerid][minigame] = NO_ZONE;
	SetPlayerInterior(0);
	notifyPlayerAction(playerid, "Ha salido de /zonaww");
	SetPlayerArmour(playerid, 0.0);
	SpawnPlayer(playerid);
	return 1;
}

CMD:pm(playerid, params[]) {
	new targetId, message[255], result;
	result = sscanf(params, "us[255]", targetId, message);
	if (result == 0) {
		if (IsPlayerConnected(targetId)) {
			if (targetId != playerid) {
				if (Players[targetId][blocked_pms] == 0) {
					new senderName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME], pmMessage[255];
					GetPlayerName(playerid, senderName, MAX_PLAYER_NAME);
					GetPlayerName(targetId, targetName, MAX_PLAYER_NAME);
					format(pmMessage, sizeof pmMessage, "[PM] %s: %s", senderName, message);
					SendClientMessage(targetId, COLOR_PM, pmMessage);
					PlayerPlaySound(targetId, 1083, 0.0, 0.0, 0.0);
					format(pmMessage, sizeof pmMessage, "[PM] -> %s: %s", targetName, message);
					SendClientMessage(playerid, COLOR_PM, pmMessage);
				} else {
					SendClientMessage(playerid, COLOR_ERROR, "Este jugador tiene bloqueados los PMs.");	
				}
			} else {
			SendClientMessage(playerid, COLOR_ERROR, "No puedes enviarte un PM a ti mismo.");
			}
		} else {
			SendClientMessage(playerid, COLOR_ERROR, "Este jugador no esta conectado.");
		}
	} else {
		SendClientMessage(playerid, COLOR_ERROR, "Uso: /pm [id] [mensaje]");
	}
	return 1;
}

CMD:ir(playerid, params[]) {
	new targetId, message[255], result;
	result = sscanf(params, "u", targetId);
	if (result == 0) {
		if (IsPlayerConnected(targetId)) {
			if (playerid != targetId) {
				if (Players[targetId][blocked_goto] == 0) {
					new playerName[MAX_PLAYER_NAME], targetName[MAX_PLAYER_NAME], Float: x, Float: y, Float: z;
					GetPlayerName(targetId, targetName, MAX_PLAYER_NAME);
					GetPlayerName(playerid, playerName, MAX_PLAYER_NAME);
					GetPlayerPos(targetId, x, y, z);
					SetPlayerPos(playerid, x, y, z);
					
					format(message, sizeof message, "%s ha ido a tu posicion.", playerName);
					SendClientMessage(targetId, COLOR_INFO, message);
					PlayerPlaySound(targetId, 1083, 0.0, 0.0, 0.0);

					format(message, sizeof message, "Has ido a la posicion de %s", targetName);
					SendClientMessage(playerid, COLOR_INFO, message);

				} else {
					SendClientMessage(playerid, COLOR_ERROR, "Este jugador esta bloqueado.");
				}
			} else {
				SendClientMessage(playerid, COLOR_ERROR, "No puedes ir a ti mismo.");
			}
		} else {
			SendClientMessage(playerid, COLOR_ERROR, "Este jugador no esta conectado.");
		}
	} else {
		SendClientMessage(playerid, COLOR_ERROR, "Uso: /ir [id]");
	}
	return 1;
}

CMD:bloquear(playerid, params[]) {
	Players[playerid][blocked_goto] = 1;
	SendClientMessage(playerid, COLOR_INFO, "Te has bloqueado, ahora nadie podra ir a tu posicion.");
	return 1;
}

CMD:desbloquear(playerid, params[]) {
	Players[playerid][blocked_goto] = 0;
	SendClientMessage(playerid, COLOR_INFO, "Te has desbloqueado, ahora podran ir a tu posicion.");
	return 1;
}

CMD:bloquearpms(playerid, params[]) {
	Players[playerid][blocked_pms] = 1;
	SendClientMessage(playerid, COLOR_INFO, "Has bloqueado los PMs.");
	return 1;
}

CMD:desbloquearpms(playerid, params[]) {
	Players[playerid][blocked_pms] = 0;
	SendClientMessage(playerid, COLOR_INFO, "Has desbloqueado los PMs.");
	return 1;
}

// #region teleports
CMD:zonaww(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE || Players[playerid][minigame] == WWZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	Players[playerid][minigame] = WWZONE;
	notifyPlayerAction(playerid, "Ha ido a /zonaww");
	SpawnPlayerInWwZone(playerid);
	SetPlayerHealth(playerid, 100.0);
	SetPlayerArmour(playerid, 100.0);
	return 1;
}

CMD:lv(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	SetPlayerPos(playerid, 2028.619995, 1544.070922, 10.820312);
	notifyPlayerAction(playerid, "Ha ido a /lv.");
	return 1;
}

CMD:sf(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	SetPlayerPos(playerid, -1969.760986, 294.444641, 35.171875);
	notifyPlayerAction(playerid, "Ha ido a /sf.");
	return 1;
}

CMD:ls(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	SetPlayerPos(playerid, 2490.676513, -1669.673706, 13.335947);
	notifyPlayerAction(playerid, "Ha ido a /ls.");
	return 1;
}

CMD:open(playerid, params[]) {
	openArenaOneGates();
	openArenaTwoGates();
	return 1;
}

CMD:close(playerid, params[]) {
	closeArenaOneGates();
	closeArenaTwoGates();
	return 1;
}

CMD:duelo(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}

	new result, challengedId, duelWeapons[25], arenaId, choosenWeapons[25], msg[200], challengedName[MAX_PLAYER_NAME], challengerName[MAX_PLAYER_NAME];
	printf("Params: %s", params);
	result = sscanf(params, "uds[25]", challengedId, arenaId, duelWeapons);
	format(choosenWeapons, sizeof choosenWeapons, "%s", duelWeapons);
	format(msg, sizeof msg, "Result: %d, challengedId: %d, duelWeapons: %s, sscanfWeapons: %s, arenaId: %d", result, challengedId, choosenWeapons, duelWeapons, arenaId);
	print(msg);
	SendClientMessage(playerid, COLOR_INFO, msg);

	if (result != 0) {
		SendClientMessage(playerid, COLOR_ERROR, "Uso: /duelo [id oponente] [arena (1|2)] [rw|ww|ww2]");
		return 1;
	}

	if (challengedId == playerid) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes retarte a ti mismo.");
		return 1;
	}

	if (!IsPlayerConnected(challengedId)) {
		SendClientMessage(playerid, COLOR_ERROR, "Este jugador no esta conectado.");
		return 1;
	}

	if (strcmp(choosenWeapons, "ww2") && strcmp(choosenWeapons, "ww") && strcmp(choosenWeapons, "rw")) {
		SendClientMessage(playerid, COLOR_ERROR, "Armas invalidas, usa: rw, ww o ww2.");
		return 1;
	}

	if (arenaId != 1 && arenaId != 2) {
		SendClientMessage(playerid, COLOR_ERROR, "Arena invalida, usa: 1 o 2.");
		return 1;
	}

	if (DuelArenas[arenaId - 1][is_occupied]) {
		SendClientMessage(playerid, COLOR_ERROR, "Esta arena esta ocupada.");
		return 1;
	}
	GetPlayerName(challengedId, challengedName, sizeof challengedName);
	GetPlayerName(playerid, challengerName, sizeof challengerName);
	format(msg, sizeof msg, "Has retado a un duelo a %s.", challengedName);
	SendClientMessage(playerid, COLOR_INFO, msg);
	
	format(msg, sizeof msg, "%s te ha retado a un duelo. usa /aceptar duelo para comenzar el duelo.", challengerName);
	SendClientMessage(challengedId, COLOR_INFO, msg);
	PlayerPlaySound(challengedId, 1138, 0.0, 0.0, 0.0);
	return 1;
}
// #endregion

GetVehicleModelIDFromName(vname[]) {
	for(new i = 0; i < 211; i++) {
		if (strfind(VehicleNames[i], vname, true) != -1) return i + 400;
	}

	return -1;
}

forward onVTimeout(playerid);
public onVTimeout(playerid) {
	KillTimer(Players[playerid][v_timer]);
	Players[playerid][v_timer] = 0;
	return 1;
}

forward notifyPlayerAction(playerid, action[]);
public notifyPlayerAction(playerid, action[]) {
	new playerName[200], message[200];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	format(message, sizeof message, "%s %s", playerName, action);
	SendClientMessageToAll(COLOR_INFO, message);
	return 1;
}

stock randomEx(min, max) {
	new rand = random(max-min)+min;    
	return rand;
}

forward SpawnPlayerInWwZone(playerid);
public SpawnPlayerInWwZone(playerid) {
	SetPlayerInterior(playerid, 15);
	new randomPos = random(sizeof(wwZones));
	SetPlayerPos(playerid, wwZones[randomPos][0], wwZones[randomPos][1], wwZones[randomPos][2]);
	ResetPlayerWeapons(playerid);
	GivePlayerWeapon(playerid, 24, 9999);
	GivePlayerWeapon(playerid, 25, 9999);
	GivePlayerWeapon(playerid, 34, 9999);
	SetPlayerSkin(playerid, Players[playerid][skin]);
	SetPlayerArmour(playerid, 100.0);
	return 1;
}

forward SpawnPlayerInNoZone(playerid);
public SpawnPlayerInNoZone(playerid) {
	new index = random(sizeof(spawns));
	SetPlayerPos(playerid, spawns[index][0], spawns[index][1], spawns[index][2]);
	SetPlayerInterior(playerid, 0);
	SetPlayerSkin(playerid, Players[playerid][skin]);
	ResetPlayerWeapons(playerid);
	GivePlayerWeapon(playerid, 24, 9999);
	GivePlayerWeapon(playerid, 26, 9999);
	GivePlayerWeapon(playerid, 28, 9999);
	GivePlayerWeapon(playerid, 31, 9999);
	GivePlayerWeapon(playerid, 34, 9999);
	SetCameraBehindPlayer(playerid);
	return 1;
}

forward clearDmgGivenTd(playerid);
public clearDmgGivenTd(playerid) {
	TextDrawHideForPlayer(playerid, Players[playerid][DMGGivenTD]);
	Players[playerid][dmg_given_td_timer] = 0;
	Players[playerid][dmg_given] = 0;
	KillTimer(Players[playerid][dmg_given_td_timer]);
	return 1;
}

forward clearDmgReceivedTd(playerid);
public clearDmgReceivedTd(playerid) {
	TextDrawHideForPlayer(playerid, Players[playerid][DMGReceivedTD]);
	Players[playerid][dmg_received_td_timer] = 0;
	Players[playerid][dmg_received] = 0;
	KillTimer(Players[playerid][dmg_received_td_timer]);
	return 1;
}

forward showDmgGivenTdForPlayer(playerid, message[]);
public showDmgGivenTdForPlayer(playerid, message[]) {
	KillTimer(Players[playerid][dmg_given_td_timer]);
	Players[playerid][dmg_given_td_timer] = SetTimerEx("clearDmgGivenTd", 4000, false, "d", playerid);
	TextDrawSetString(Players[playerid][DMGGivenTD], message);
	TextDrawShowForPlayer(playerid, Players[playerid][DMGGivenTD]);
	return 1;
}

forward showDmgReceivedTdForPlayer(playerid, message[]);
public showDmgReceivedTdForPlayer(playerid, message[]) {
	KillTimer(Players[playerid][dmg_received_td_timer]);
	Players[playerid][dmg_received_td_timer] = SetTimerEx("clearDmgReceivedTd", 4000, false, "d", playerid);
	TextDrawSetString(Players[playerid][DMGReceivedTD], message);
	TextDrawShowForPlayer(playerid, Players[playerid][DMGReceivedTD]);
	return 1;
}

forward openArenaOneGates();
public openArenaOneGates() {
	MoveObject(ArenaOneGateOne, 2646.3000000, 1195.2000000, 36.6000000, 2, 0.0000000,0.0000000,0.4320000);
	MoveObject(ArenaOneGateTwo, 2644.9004000, 1226.5996000, 36.6000000, 2, 0.0000000,0.0000000,0.0000000);
	return 1;
}

forward closeArenaOneGates();
public closeArenaOneGates() {
	MoveObject(ArenaOneGateOne, 2646.2998000, 1195.2002000, 29.5000000, 2, 0.0000000,0.0000000,0.4320000);
	MoveObject(ArenaOneGateTwo, 2644.8999000, 1226.6000000, 29.5000000, 2, 0.0000000,0.0000000,0.0000000);
	return 1;
}

forward openArenaTwoGates();
public openArenaTwoGates() {
	MoveObject(ArenaTwoGateOne, 1897.9004000, 1321.0000000, 31.4000000, 2, 0.0000000,0.0000000,0.4320000);
	MoveObject(ArenaTwoGateTwo, 1901.0996000, 1369.5996000, 31.4000000, 2, 0.0000000,0.0000000,0.0000000);
	return 1;
}

forward closeArenaTwoGates();
public closeArenaTwoGates() {
	MoveObject(ArenaTwoGateOne, 1897.9000000, 1321.0000000, 25.4000000, 2, 0.0000000,0.0000000,0.4320000);
	MoveObject(ArenaTwoGateTwo, 1901.1000000, 1369.6000000, 25.4000000, 2, 0.0000000,0.0000000,0.0000000);
	return 1;
}

forward resetArenas();
public resetArenas() {
	clearArena(0);
	clearArena(1);
	return 1;
}

forward clearArena(arenaId);
public clearArena(arenaId) {
	DuelArenas[arenaId][is_occupied] = false;
	DuelArenas[arenaId][challenger_id] = INVALID_PLAYER_ID;
	DuelArenas[arenaId][challenged_id] = INVALID_PLAYER_ID;
	DuelArenas[arenaId][countdown] = 0;
	return 1;
}