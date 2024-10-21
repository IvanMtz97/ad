#include <a_samp>
#include <a_mysql>

#undef	MAX_PLAYERS
#define MAX_PLAYERS 50

#define MYSQL_HOST "localhost"
#define MYSQL_USER "root"
#define MYSQL_PASS "Randomly97."
#define MYSQL_NAME "ad"

#define	SECONDS_TO_LOGIN 	30

new MySQL: dbclient;
new g_MysqlRaceCheck[MAX_PLAYERS];
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
}
new Players[MAX_PLAYERS][PLAYER];

#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_SIGNED_OUT 0x9b9b9b
#define COLOR_SUCCESS 0x69ff61AA
#define COLOR_ERROR 0xff4d4fAA

#define COLOR_RANK_1 0xFFFFFFFF

enum
{
	DIALOG_UNUSED,

	DIALOG_LOGIN,
	DIALOG_REGISTER
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
	new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	dbclient = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_NAME, option_id);
	if (dbclient == MYSQL_INVALID_HANDLE || mysql_errno(dbclient) != 0) {
		new db_err_message[128];
		format(db_err_message, sizeof(db_err_message), "[DB] Error connecting to database: %i", mysql_errno(dbclient));
		print(db_err_message);
		SendRconCommand("exit");
	} else {
		print("[DB] Connected to database successfully");
	}
	SetGameModeText("AD v0.1");
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

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
	//  SetSpawnInfo(playerid, 2496.454101, -1681.430786, 13.351849, 0.00, 0.00, 0.00, 0, 0, 0, 0, 0, 0);
	SetPlayerInterior(playerid, 0);
	SetPlayerPos(playerid, 2496.454101, -1681.430786, 13.351849);
	SetCameraBehindPlayer(playerid);
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
	if (strcmp("/pos", cmdtext, true, 10) == 0)
	{
		new Float: x, Float: y, Float: z;
		GetPlayerPos(playerid, x, y, z);
		printf("Player %d's position: %f, %f, %f", playerid, x, y, z);
		// Do something here
		return 1;
	}

	if (strcmp("/infernus", cmdtext, true, 10) == 0) {
		new Float: x, Float: y, Float: z;
		GetPlayerPos(playerid, x, y, z);
		new vehicleid = CreateVehicle(411, x, y, z, 0.0, 0, 0, 0);
		SetVehicleParamsForPlayer(vehicleid, playerid, true);
		LinkVehicleToInterior(vehicleid, 0);
		SetVehicleToRespawn(vehicleid);
		return 1;
	}
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

			if (strlen(inputtext) <= 5 || strlen(inputtext) > 20) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registration", "Your password must met the following:\n- Longer than 5 characters\n- Less than 20 characters\nPlease enter your password in the field below:", "Register", "Cancel");

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
				SendClientMessage(playerid, COLOR_SUCCESS, "You have been successfully logged in.");
				PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
				cache_set_active(Players[playerid][Cache_ID]);
				cache_delete(Players[playerid][Cache_ID]);

				KillTimer(Players[playerid][login_timer]);
				Players[playerid][login_timer] = 0;
				Players[playerid][is_logged_in] = true;

				SetSpawnInfo(playerid, NO_TEAM, 0, 1958.3783, 1343.1572, 15.3746, 0.0, 0, 0, 0, 0, 0, 0);
				SpawnPlayer(playerid);
			} else {
				Players[playerid][loggin_attempts]++;

				if (Players[playerid][loggin_attempts] >= 3) {
					SendClientMessage(playerid, COLOR_ERROR, "You have mistyped your password too often (3 times).");
					DelayedKick(playerid);
				} else {
					ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Wrong password!\nPlease enter your password in the field below:", "Login", "Abort");
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
		cache_get_value(0, "password", Players[playerid][password], 65);
		cache_get_value(0, "salt", Players[playerid][salt], 17);
		Players[playerid][Cache_ID] = cache_save();
		format(message, sizeof message, "This account (%s) is registered. Please login by entering your password in the field below:", Players[playerid][nick]);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", message, "Login", "Cancel");
		Players[playerid][login_timer] = SetTimerEx("OnLoginTimeout", SECONDS_TO_LOGIN * 1000, false, "d", playerid);
	} else {
		format(message, sizeof message, "Welcome %s, you can register by entering your password in the field below:", Players[playerid][nick]);
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registration", message, "Register", "Cancel");
	}
	return 1;
}

forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	Players[playerid][id] = cache_insert_id();

	SendClientMessage(playerid, COLOR_SUCCESS, "Registered successfully!");
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