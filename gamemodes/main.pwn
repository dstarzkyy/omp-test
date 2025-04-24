#define MIXED_SPELLINGS

#include <open.mp>

#define KILLS_PER_LEVEL 3

#define BODYPART_HEAD 9

new const
    Float:gRandPos[9][4] = {
        {-1291.6622, 2513.7566, 87.0500, 355.3697},
        {-1303.8662, 2527.4270, 87.5878, 358.6714},
        {-1308.1099, 2544.3853, 87.7422, 171.4412},
        {-1321.0725, 2526.1138, 87.4379, 183.3481},
        {-1335.7893, 2520.8984, 87.0469, 270.7455},
        {-1298.5408, 2547.2991, 87.6747, 356.4313},
        {-1291.3345, 2533.8853, 87.7422, 92.7705},
        {-1288.5410, 2528.5769, 87.6331, 183.0114},
        {-1316.3402, 2499.9949, 87.0420, 271.8305}
    },
    WEAPON:gWeaponList[] = {
        WEAPON_COLT45,
        WEAPON_SILENCED,
        WEAPON_TEC9,
        WEAPON_UZI,
        WEAPON_MP5,
        WEAPON_GRENADE,
        WEAPON_SHOTGUN,
        WEAPON_SHOTGSPA,
        WEAPON_SAWEDOFF,
        WEAPON_RIFLE,
        WEAPON_AK47,
        WEAPON_M4,
        WEAPON_SNIPER,
        WEAPON_DEAGLE
    }
;

enum e_STATUS {
    e_LEVEL,
    e_KILLS_AT_LEVEL,
    bool:e_DEAD,
    bool:e_HOLDING_PRIMARY // Whether the player holds their primary weapon
};

new
    gPlayerStatus[MAX_PLAYERS][e_STATUS],
    Text:gRespawn,
    bool:gGameInProgress
;

forward Restart();

main() {
    print("\n----------------------------------");
    print(" gungame is a gun game mode released as");
    print(" an example mode for open.mp");
    print(" ");
    print(" Author: NotUnlikeTheWaves (github)");
    print("----------------------------------\n");
}

public OnGameModeInit() {
    SetGameModeText("Gun Game");
    AddPlayerClass(0, -1291.6622, 2513.7566, 87.0500, 355.3697, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
    gRespawn = TextDrawCreate(320.000000, 155.000000, "~y~Press '~r~~k~~VEHICLE_ENTER_EXIT~~y~' to spawn!");
    TextDrawAlignment(gRespawn, TEXT_DRAW_ALIGN_CENTER);
    TextDrawBackgroundColor(gRespawn, 255);
    TextDrawFont(gRespawn, TEXT_DRAW_FONT_2);
    TextDrawLetterSize(gRespawn, 0.549999, 1.500000);
    TextDrawColor(gRespawn, -65281);
    TextDrawSetOutline(gRespawn, 0);
    TextDrawSetProportional(gRespawn, true);
    TextDrawSetShadow(gRespawn, 3);
    gGameInProgress = true;
    return 1;
}

public OnGameModeExit() {
    return 1;
}

public OnPlayerRequestClass(playerid, classid) {
    SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraPos(playerid, -1251.1089, 2551.7546, 104.6863);
    SetPlayerCameraLookAt(playerid, -1302.1554, 2533.4226, 93.8427);
    return 1;
}

public OnPlayerConnect(playerid) {
    SendClientMessage(playerid, 0xFF0000FF, "Welcome to Gun Game! The rules are simple:");
    SendClientMessage(playerid, 0xFFFFFFFF, "You start with two pistols. You advance to the next weapon by killing other players.");
    SendClientMessage(playerid, 0xFFFFFFFF, "The last stage is the Desert Eagle! Get enough kills with it, and you win the round!");
    SendClientMessage(playerid, 0xFFFFFFFF, "You also have a knife. Use it to demote other players!");
    SendClientMessage(playerid, 0xFFFFFFFF, "Have fun, and let the games begin!");
    gPlayerStatus[playerid][e_LEVEL] = 0;
    gPlayerStatus[playerid][e_KILLS_AT_LEVEL] = 0;
    gPlayerStatus[playerid][e_DEAD] = true;
    gPlayerStatus[playerid][e_HOLDING_PRIMARY] = true;
    TextDrawHideForPlayer(playerid, gRespawn);
    SetPlayerColor(playerid, 0xFF0000FF);
    return 1;
}

public OnPlayerSpawn(playerid) {
    // Set position
    new rand = random(9);
    SetPlayerPos(playerid, gRandPos[rand][0], gRandPos[rand][1], gRandPos[rand][2]);
    SetPlayerFacingAngle(playerid, gRandPos[rand][3]);
    SetPlayerWorldBounds(playerid, -1274.2817, -1358.5095, 2575.6509, 2472.3486);
    SetCameraBehindPlayer(playerid);

    // Give the right weapons to the player
    GivePlayerWeapon(playerid, WEAPON_KNIFE, 1);
    GivePlayerWeapon(playerid, gWeaponList[gPlayerStatus[playerid][e_LEVEL]], 65535);

    // General stuff
    gPlayerStatus[playerid][e_DEAD] = false;
    gPlayerStatus[playerid][e_HOLDING_PRIMARY] = true;
    return 1;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason) {
    SendDeathMessage(killerid, playerid, reason);
    TogglePlayerSpectating(playerid, true);
    TextDrawShowForPlayer(playerid, gRespawn);
    gPlayerStatus[playerid][e_DEAD] = true;
    if(killerid == INVALID_PLAYER_ID) {
        SetPlayerCameraPos(playerid, -1251.1089, 2551.7546, 104.6863);
        SetPlayerCameraLookAt(playerid, -1302.1554, 2533.4226, 93.8427);
    } else {
        PlayerSpectatePlayer(playerid, killerid);

        // Knife deaths are humiliating, and demote the player.
        if(reason == WEAPON_KNIFE) {
            GameTextForPlayer(killerid, "~r~Humiliation!~n~~y~You demoted someone!", 1650, 6);
            GameTextForPlayer(playerid, "~r~Humiliated~n~~y~You got demoted!", 1650, 6);
            if(gPlayerStatus[playerid][e_LEVEL] != 0) gPlayerStatus[playerid][e_LEVEL]--;
            gPlayerStatus[playerid][e_KILLS_AT_LEVEL] = 0;

        }
        gPlayerStatus[killerid][e_KILLS_AT_LEVEL]++;
        if(gPlayerStatus[killerid][e_KILLS_AT_LEVEL] == KILLS_PER_LEVEL) {
            gPlayerStatus[killerid][e_KILLS_AT_LEVEL] = 0;
            gPlayerStatus[killerid][e_LEVEL]++;

            //Player has won the game.
            if(gPlayerStatus[killerid][e_LEVEL] == sizeof gWeaponList) {
                EndRound();
            } else {
                GameTextForPlayer(killerid, "~r~Player Killed!~n~~y~Advanced to the next tier!", 1650, 6);
                SetPlayerScore(killerid, gPlayerStatus[killerid][e_LEVEL] + 1);
                ResetPlayerWeapons(killerid);
                GivePlayerWeapon(killerid, WEAPON_KNIFE, 1);
                GivePlayerWeapon(killerid, gWeaponList[gPlayerStatus[killerid][e_LEVEL]], 65535);
            }
        } else {
            ShowKillsTillNextLevel(killerid);
        }
    }
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, WEAPON:weaponid, bodypart) {
    new Float:health;
    GetPlayerHealth(playerid, health);

    // Take twice the damage as you normally would, to increase the pace in the game.
    new Float:multiplier = 2.0;

    // Make headshots do 50% more damage over the regular multiplier
    if(bodypart == BODYPART_HEAD) {
        multiplier = 3.0;
    }
    SetPlayerHealth(playerid, health - amount * multiplier);
}

public OnPlayerUpdate(playerid) {
    if(gPlayerStatus[playerid][e_DEAD] == false) {
        // We want to avoid the player switching to his hands as a weapon
        // A player should only be able to use his knife and the weapon given to them.
        if(!GetPlayerWeapon(playerid)) {
            if(gPlayerStatus[playerid][e_HOLDING_PRIMARY] == true) {
                SetPlayerArmedWeapon(playerid, WEAPON_KNIFE);
                gPlayerStatus[playerid][e_HOLDING_PRIMARY] = false;
            } else {
                SetPlayerArmedWeapon(playerid, gWeaponList[gPlayerStatus[playerid][e_LEVEL]]);
                gPlayerStatus[playerid][e_HOLDING_PRIMARY] = true;
            }
        } else {
            gPlayerStatus[playerid][e_HOLDING_PRIMARY] = !(GetPlayerWeapon(playerid) == WEAPON_KNIFE);
        }

    } else {
        SetPlayerCameraPos(playerid, -1251.1089, 2551.7546, 104.6863);
        SetPlayerCameraLookAt(playerid, -1302.1554, 2533.4226, 93.8427);
        new KEY:keys[3];
        GetPlayerKeys(playerid, keys[0], keys[1], keys[2]);
        if(keys[0] & KEY_SECONDARY_ATTACK && gGameInProgress == true) {
            TogglePlayerSpectating(playerid, false);
            SpawnPlayer(playerid);
            TextDrawHideForPlayer(playerid, gRespawn);
            gPlayerStatus[playerid][e_DEAD] = false;
        }
    }
    return 1;
}

public Restart() {
    SendRconCommand("gmx");
}

EndRound()
{
    SendClientMessageToAll(0x008000FF, "The game has ended!");
    SendClientMessageToAll(0x008000FF, "A new round will start in 8 seconds.");
    gGameInProgress = false;

    // Print the top three best players.
    new highest[3] = {INVALID_PLAYER_ID, ...};
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i))
        {
            continue;
        }
        TogglePlayerSpectating(i, true);
        SetPlayerCameraPos(i, -1251.1089, 2551.7546, 104.6863);
        SetPlayerCameraLookAt(i, -1302.1554, 2533.4226, 93.8427);

        // Find the player with the highest score.
        if(GetPlayerScore(i) > GetPlayerScore(highest[0]))
        {
            highest[2] = highest[1];
            highest[1] = highest[0];
            highest[0] = i;
        }
        else if(GetPlayerScore(i) > GetPlayerScore(highest[1]))
        {
            highest[2] = highest[1];
            highest[1] = i;
        }
        else if(GetPlayerScore(i) > GetPlayerScore(highest[2]))
        {
            highest[2] = i;
        }
    }

    new string[144], pName[3][MAX_PLAYER_NAME + 1];
    GetPlayerName(highest[0], pName[0], MAX_PLAYER_NAME);
    GetPlayerName(highest[1], pName[1], MAX_PLAYER_NAME);
    GetPlayerName(highest[2], pName[2], MAX_PLAYER_NAME);
    format(string, sizeof string,
        "~r~The match ended!~n~~g~1. %02i - %s~n~~y~2. %02i - %s~n~~r~~h~3. %02i - %s", 
        GetPlayerScore(highest[0]),
        pName[0],
        GetPlayerScore(highest[1]),
        pName[1],
        GetPlayerScore(highest[2]),
        pName[2]);
    GameTextForAll(string, 7500, 1);
    SetTimer("Restart", 8000, false);
}

ShowKillsTillNextLevel(playerid)
{
    new str[128];
    format(str, sizeof str, "~r~%i~y~ kills till level up!", KILLS_PER_LEVEL - gPlayerStatus[playerid][e_KILLS_AT_LEVEL]);
    GameTextForPlayer(playerid, str, 1000, 4);
}
