
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
}
new Players[MAX_PLAYERS][PLAYER];

#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_SIGNED_OUT 0x9b9b9b
#define COLOR_SUCCESS 0x69ff61AA
#define COLOR_ERROR 0xff4d4fAA
#define COLOR_INFO 0xe6e65aAA

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
	{ -1463.177368, 935.461730, 1036.595825 }
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
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if (Players[playerid][minigame] == NO_ZONE) {
		SpawnPlayerInRandomSpawn(playerid);
	} else if (Players[playerid][minigame] == WWZONE) {
		SpawnPlayerInWwZone(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
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

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch (dialogid) {
		case DIALOG_UNUSED: return 1;

		case DIALOG_REGISTER: {
			if (!response) return Kick(playerid);

			if (strlen(inputtext) <= 5 || strlen(inputtext) > 20) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Regustri", "Tu contrasena debe cumplir lo siguiente:\n- Mas de 5 caracteres\n- Menor a 20 caracteres\nPorfavor ingresa la contrasena:", "Registrarme", "Cancelar");

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
	SpawnPlayer(playerid);
	return 1;
}

// #region teleports
CMD:zonaww(playerid, params[]) {
	if (Players[playerid][minigame] != NO_ZONE) {
		SendClientMessage(playerid, COLOR_ERROR, "No puedes usar este comando ahora, usa /salir.");
		return 1;
	}
	Players[playerid][minigame] = WWZONE;
	notifyPlayerAction(playerid, "Ha ido a /zonaww");
	SpawnPlayerInWwZone(playerid);
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
	return 1;
}

forward SpawnPlayerInRandomSpawn(playerid);
public SpawnPlayerInRandomSpawn(playerid) {
		new index = random(sizeof(spawns));
		SetPlayerPos(playerid, spawns[index][0], spawns[index][1], spawns[index][2]);
		SetPlayerInterior(playerid, 0);
		SetPlayerSkin(playerid, Players[playerid][skin]);
		ResetPlayerWeapons(playerid);
		GivePlayerWeapon(playerid, 24, 9999);
		GivePlayerWeapon(playerid, 26, 9999);
		GivePlayerWeapon(playerid, 28, 9999);
		GivePlayerWeapon(playerid, 33, 9999);
		SetCameraBehindPlayer(playerid);
}