#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "0.0.1"

#define SOUND_VOLUME_MAX 100
#define SOUND_VOLUME_MIN 0

#define ROULETTE_MAX_TICK_COUNT 25
#define ROULETTE_TICK_INITIAL 0.05
#define ROULETTE_TICK_MULTIPLIER 1.15

#define ROULETTE_STRING_EASY        "||||   Easy   ||||"
#define ROULETTE_STRING_NORMAL      "||||  Normal  ||||"
#define ROULETTE_STRING_ADVANCED    "|||| Advanced ||||"
#define ROULETTE_STRING_EXPERT      "||||  Expert  ||||"

ConVar 
    g_cvPluginEnabled,
    g_cvReroll,
    g_cvRouletteCountdownTime,
    g_cvWinWeightEasy,
    g_cvWinWeightNormal,
    g_cvWinWeightAdvanced,
    g_cvWinWeightExpert,
    g_cvZDifficulty,
    g_cvRouletteSoundTick,
    g_cvRouletteSoundChosen,
    g_cvRouletteSoundCountdown;

int
    g_iMaxReroll,
    g_iTimesRerolled,
    g_iRouletteCountdownTime,
    g_iWinWeightEasy,
    g_iWinWeightNormal,
    g_iWinWeightAdvanced,
    g_iWinWeightExpert,
    g_iWinWeightTotal,
    g_iTimesRouletteTicked;

bool
    g_bPluginEnabled,
    g_bPlayerJoinedAfterMapInitialize,
    g_bIsRouletteRolling;

char
    g_cRouletteSoundTick[128],
    g_cRouletteSoundChosen[128],
    g_cRouletteSoundCountdown[128];

Handle
    g_hSoundVolumeCookie,
    g_hSoundToggleCookie;


bool g_bPlayerSoundDisabled[MAXPLAYERS+1];
float g_fPlayerSoundVolume[MAXPLAYERS+1];

enum {
    DIFFICULTY_EASY = 0,
    DIFFICULTY_NORMAL,
    DIFFICULTY_ADVANCED,
    DIFFICULTY_EXPERT,
    DIFFICULTY_NONE,
}

public Plugin myinfo = 
{
    name = "[L4D2] Difficulty randomizer",
    author = "faketuna",
    description = "Randomize difficulty per map change.",
    version = PLUGIN_VERSION,
    url = "https://short.f2a.dev/s/github"
};

public void OnPluginStart() {
    CreateConVar("sm_drand_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
    g_cvPluginEnabled           = CreateConVar("sm_drand_enabled", "1", "1 Enabled | 0 Disabled", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvReroll                  = CreateConVar("sm_drand_reroll", "1", "How many times can be rerolled", FCVAR_NONE, true, 0.0, false);
    g_cvWinWeightEasy           = CreateConVar("sm_drand_win_wieght_easy", "25", "Win chance rate of Easy difficulty.", FCVAR_NONE, true, 0.0, true, 100.0);
    g_cvWinWeightNormal         = CreateConVar("sm_drand_win_wieght_normal", "25", "Win chance rate of Normal difficulty.", FCVAR_NONE, true, 0.0, true, 100.0);
    g_cvWinWeightAdvanced       = CreateConVar("sm_drand_win_wieght_advanced", "25", "Win chance rate of Advanced difficulty.", FCVAR_NONE, true, 0.0, true, 100.0);
    g_cvWinWeightExpert         = CreateConVar("sm_drand_win_wieght_expert", "25", "Win chance rate of Expert difficulty.", FCVAR_NONE, true, 0.0, true, 100.0);
    g_cvRouletteCountdownTime   = CreateConVar("sm_drand_roulette_countdown_time", "10", "How many seconds to countdown for starting roulette after first player joined the game", FCVAR_NONE, true, 0.0, true, 30.0);
    g_cvRouletteSoundTick       = CreateConVar("sm_drand_roulette_sound_tick", "weapons/hegrenade/beep.wav", "Specify the ticking sound of roulette. Requires sound path include extension.", FCVAR_NONE);
    g_cvRouletteSoundChosen     = CreateConVar("sm_drand_roulette_sound_chosen", "level/bell_normal.wav", "Specify the chosen sound of roulette. Requires sound path include extension.", FCVAR_NONE);
    g_cvRouletteSoundCountdown  = CreateConVar("sm_drand_roulette_sound_countdown", "buttons/blip1.wav", "Specify the countdown sound of roulette. Requires sound path include extension.", FCVAR_NONE);

    g_cvZDifficulty             = FindConVar("z_difficulty");

    g_cvPluginEnabled.AddChangeHook(OnCvarsChanged);
    g_cvReroll.AddChangeHook(OnCvarsChanged);
    g_cvWinWeightEasy.AddChangeHook(OnCvarsChanged);
    g_cvWinWeightNormal.AddChangeHook(OnCvarsChanged);
    g_cvWinWeightAdvanced.AddChangeHook(OnCvarsChanged);
    g_cvWinWeightExpert.AddChangeHook(OnCvarsChanged);
    g_cvRouletteCountdownTime.AddChangeHook(OnCvarsChanged);
    g_cvRouletteSoundTick.AddChangeHook(OnCvarsChanged);
    g_cvRouletteSoundChosen.AddChangeHook(OnCvarsChanged);
    g_cvRouletteSoundCountdown.AddChangeHook(OnCvarsChanged);

    RegConsoleCmd("sm_reroll", CommandReroll, "Reroll the difficulty roulette");
    RegConsoleCmd("sm_dr_volume", CommandDRVolume, "Set Difficulty randomizer sound volume per player.");
    RegConsoleCmd("sm_dr_toggle", CommandDRToggle, "Toggle Difficulty randomizer sound per player.");
    RegConsoleCmd("sm_dr_menu", CommandDRMenu, "Open settings menu");

    g_hSoundVolumeCookie            = RegClientCookie("cookie_dr_volume", "Difficulty randomzier volume", CookieAccess_Protected);
    g_hSoundToggleCookie            = RegClientCookie("cookie_dr_toggle", "Difficulty randomzier toggle", CookieAccess_Protected);

    SetCookieMenuItem(SoundSettingsMenu, 0 ,"Difficulty Randomizer");

    LoadTranslations("common.phrases");
    LoadTranslations("l4d2_difficulty_randomizer.phrases");

    g_iTimesRerolled = 0;
    g_bIsRouletteRolling = false;

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientConnected(i)) {
            if(AreClientCookiesCached(i)) {
                OnClientCookiesCached(i);
            }
        }
    }
}

public void OnClientCookiesCached(int client) {
    if (IsFakeClient(client)) return;

    char cookieValue[128];
    GetClientCookie(client, g_hSoundVolumeCookie, cookieValue, sizeof(cookieValue));

    if (!StrEqual(cookieValue, "")) {
        g_fPlayerSoundVolume[client] = StringToFloat(cookieValue);
    } else {
        g_fPlayerSoundVolume[client] = 1.0;
        SetClientCookie(client, g_hSoundVolumeCookie, "1.0");
    }

    GetClientCookie(client, g_hSoundToggleCookie, cookieValue, sizeof(cookieValue));

    if (!StrEqual(cookieValue, "")) {
        g_bPlayerSoundDisabled[client] = view_as<bool>(StringToInt(cookieValue));
    } else {
        g_bPlayerSoundDisabled[client] = false;
        SetClientCookie(client, g_hSoundToggleCookie, "0");
    }
}

void SyncConVarValues() {
    g_bPluginEnabled            = g_cvPluginEnabled.BoolValue;
    g_iMaxReroll                = g_cvReroll.IntValue;
    g_iWinWeightEasy            = g_cvWinWeightEasy.IntValue;
    g_iWinWeightNormal          = g_cvWinWeightNormal.IntValue;
    g_iWinWeightAdvanced        = g_cvWinWeightAdvanced.IntValue;
    g_iWinWeightExpert          = g_cvWinWeightExpert.IntValue;
    g_iRouletteCountdownTime    = g_cvRouletteCountdownTime.IntValue;
    g_iWinWeightTotal           = g_iWinWeightEasy + g_iWinWeightNormal + g_iWinWeightAdvanced + g_iWinWeightExpert;

    char buff[128];
    GetConVarString(g_cvRouletteSoundTick, buff, sizeof(buff));
    strcopy(g_cRouletteSoundTick, sizeof(g_cRouletteSoundTick), buff);
    GetConVarString(g_cvRouletteSoundChosen, buff, sizeof(buff));
    strcopy(g_cRouletteSoundChosen, sizeof(g_cRouletteSoundChosen), buff);
    GetConVarString(g_cvRouletteSoundCountdown, buff, sizeof(buff));
    strcopy(g_cRouletteSoundCountdown, sizeof(g_cRouletteSoundCountdown), buff);
}

public void OnConfigsExecuted() {
    SyncConVarValues();
}

public void OnCvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    SyncConVarValues();
}


public Action CommandReroll(int client, int args) {
    if(client == 0) return Plugin_Handled;

    if(!g_bPluginEnabled) {
        CReplyToCommand(client, "%t%t", "drand prefix", "drand");
        return Plugin_Handled;
    }

    if(g_iTimesRerolled >= g_iMaxReroll) {
        CReplyToCommand(client, "%t%t", "drand prefix", "drand max reroll reached", g_iMaxReroll);
        return Plugin_Handled;
    }

    if(g_bIsRouletteRolling) {
        CReplyToCommand(client, "%t%t", "drand prefix", "drand reroll is in progress");
        return Plugin_Handled;
    }

    g_iTimesRerolled++;
    g_bIsRouletteRolling = true;
    CPrintToChatAll("%t%t", "drand prefix", "drand reroll starting");
    CreateTimer(1.0, DelayedRouletteStartTimer, g_iRouletteCountdownTime);
    return Plugin_Handled;
}

public Action CommandDRMenu(int client, int args) {
    DisplaySettingsMenu(client);
    return Plugin_Handled;
}

public Action CommandDRToggle(int client, int args) {
    g_bPlayerSoundDisabled[client] = !g_bPlayerSoundDisabled[client];
    CPrintToChat(client, "%t%t", "drand prefix", !g_bPlayerSoundDisabled[client] ? "drand cmd toggle enable" : "drand cmd toggle disable");
    SetClientCookie(client, g_hSoundToggleCookie, g_bPlayerSoundDisabled[client] ? "1" : "0");
    return Plugin_Handled;
}

public Action CommandDRVolume(int client, int args) {
    if(args >= 1) {
        char arg1[4];
        GetCmdArg(1, arg1, sizeof(arg1));
        if(!IsOnlyDicimal(arg1)) {
            CPrintToChat(client, "%t%t", "drand prefix", "drand cmd invalid arguments");
            return Plugin_Handled;
        }
        int arg = StringToInt(arg1);
        if(arg > SOUND_VOLUME_MAX || SOUND_VOLUME_MIN > arg) {
            CPrintToChat(client, "%t%t", "drand prefix", "drand cmd value out of range", arg, SOUND_VOLUME_MIN, SOUND_VOLUME_MAX);
            return Plugin_Handled;
        }

        g_fPlayerSoundVolume[client] = float(StringToInt(arg1)) / 100;
        char buff[6];
        FloatToString(g_fPlayerSoundVolume[client], buff, sizeof(buff));
        SetClientCookie(client, g_hSoundVolumeCookie, buff);
        CPrintToChat(client, "%t%t", "drand prefix", "drand cmd set volume", arg1);
        return Plugin_Handled;
    }

    DisplaySettingsMenu(client);
    return Plugin_Handled;
}

public void OnMapEnd() {
    g_bPlayerJoinedAfterMapInitialize = false;
    g_iTimesRerolled = 0;
}

public void OnClientPutInServer(int client) {
    if(IsFakeClient(client)) return;
    if(!g_bPluginEnabled) return;
    if(g_bPlayerJoinedAfterMapInitialize) return;

    g_bIsRouletteRolling = true;
    CreateTimer(1.0, DelayedRouletteStartTimer, g_iRouletteCountdownTime);
    g_bPlayerJoinedAfterMapInitialize = true;
}

public Action DelayedRouletteStartTimer(Handle timer, int count) {
    if(!g_bPluginEnabled) return Plugin_Stop;
    if(count <= 0) {
        StartRoulette();
        return Plugin_Stop;
    }
    PrintHintTextToAll("%t", "drand roulette starts in", count);
    count--;

    PlaySound(g_cRouletteSoundCountdown);
    CreateTimer(1.0, DelayedRouletteStartTimer, count);
    return Plugin_Continue;
}

public void StartRoulette() {
    g_iTimesRouletteTicked = 0;
    g_bIsRouletteRolling   = true;
    CreateTimer(ROULETTE_TICK_INITIAL, RouletteTimer, ROULETTE_TICK_INITIAL);
}

public Action RouletteTimer(Handle timer, float nextTimerTime) {
    if(!g_bPluginEnabled) return Plugin_Stop;
    int difficulty = Roulette();
    if(g_iTimesRouletteTicked >= ROULETTE_MAX_TICK_COUNT) {
        char difficultyString[16];
        switch(difficulty) {
            case DIFFICULTY_EASY: {
                Format(difficultyString, sizeof(difficultyString), "Easy");
                PrintHintTextToAll(ROULETTE_STRING_EASY);
                CPrintToChatAll("%t%t", "drand prefix", "drand new difficulty chosen easy");
            }
            case DIFFICULTY_NORMAL: {
                Format(difficultyString, sizeof(difficultyString), "Normal");
                PrintHintTextToAll(ROULETTE_STRING_NORMAL);
                CPrintToChatAll("%t%t", "drand prefix", "drand new difficulty chosen normal");
            }
            case DIFFICULTY_ADVANCED: {
                Format(difficultyString, sizeof(difficultyString), "Hard");
                PrintHintTextToAll(ROULETTE_STRING_ADVANCED);
                CPrintToChatAll("%t%t", "drand prefix", "drand new difficulty chosen advanced");
            }
            case DIFFICULTY_EXPERT: {
                Format(difficultyString, sizeof(difficultyString), "Impossible");
                PrintHintTextToAll(ROULETTE_STRING_EXPERT);
                CPrintToChatAll("%t%t", "drand prefix", "drand new difficulty chosen expert");
            }
        }
        g_cvZDifficulty.SetString(difficultyString, true, false);
        g_bIsRouletteRolling = false;
        PlaySound(g_cRouletteSoundChosen);
        return Plugin_Stop;
    }

    switch(difficulty) {
        case DIFFICULTY_EASY: {
            PrintHintTextToAll(ROULETTE_STRING_EASY);
        }
        case DIFFICULTY_NORMAL: {
            PrintHintTextToAll(ROULETTE_STRING_NORMAL);
        }
        case DIFFICULTY_ADVANCED: {
            PrintHintTextToAll(ROULETTE_STRING_ADVANCED);
        }
        case DIFFICULTY_EXPERT: {
            PrintHintTextToAll(ROULETTE_STRING_EXPERT);
        }
    }

    PlaySound(g_cRouletteSoundTick);
    nextTimerTime = nextTimerTime*ROULETTE_TICK_MULTIPLIER;
    CreateTimer(nextTimerTime, RouletteTimer, nextTimerTime);
    g_iTimesRouletteTicked++;
    return Plugin_Stop;
}

public void PlaySound(const char[] sample) {
    for(int i = 1; i < MaxClients; i++) {
        if(!IsClientInGame(i) || IsFakeClient(i)) 
            continue;
        
        if(g_bPlayerSoundDisabled[i])
            continue;
        
        EmitSoundToClient(
            i,
            sample,
            SOUND_FROM_PLAYER,
            SNDCHAN_STATIC,
            SNDLEVEL_NORMAL,
            SND_NOFLAGS,
            g_fPlayerSoundVolume[i],
            SNDPITCH_NORMAL,
            0,
            NULL_VECTOR,
            NULL_VECTOR,
            true,
            0.0
        );
        
    }
}

public int Roulette() {
    int random = GetRandomInt(0, g_iWinWeightTotal);
    if(random <= g_iWinWeightEasy) {
        return DIFFICULTY_EASY;
    }
    else if(random <= g_iWinWeightNormal + g_iWinWeightEasy){
        return DIFFICULTY_NORMAL;
    }
    else if(random <= g_iWinWeightAdvanced + g_iWinWeightNormal + g_iWinWeightEasy){
        return DIFFICULTY_ADVANCED;
    }
    else if(random <= g_iWinWeightExpert + g_iWinWeightAdvanced + g_iWinWeightNormal + g_iWinWeightEasy){
        return DIFFICULTY_EXPERT;
    }
    return DIFFICULTY_NONE;
}


void DisplaySettingsMenu(int client)
{
    SetGlobalTransTarget(client);
    Menu prefmenu = CreateMenu(SoundSettingHandler, MENU_ACTIONS_DEFAULT);

    char menuTitle[64];
    Format(menuTitle, sizeof(menuTitle), "%t", "drand menu title");
    prefmenu.SetTitle(menuTitle);

    char soundDisabled[64], soundVolume[64];

    Format(soundDisabled, sizeof(soundDisabled), "%t%t","drand menu disable sounds", g_bPlayerSoundDisabled[client] ? "Yes" : "No");
    prefmenu.AddItem("drand_pref_disable", soundDisabled);

    Format(soundVolume, sizeof(soundVolume), "%t%.0f%","drand menu volume", g_fPlayerSoundVolume[client] * 100);
    switch (RoundToZero((g_fPlayerSoundVolume[client]*100)))
    {
        case 10: { prefmenu.AddItem("drand_pref_volume_100", soundVolume);}
        case 20: { prefmenu.AddItem("drand_pref_volume_10", soundVolume);}
        case 30: { prefmenu.AddItem("drand_pref_volume_20", soundVolume);}
        case 40: { prefmenu.AddItem("drand_pref_volume_30", soundVolume);}
        case 50: { prefmenu.AddItem("drand_pref_volume_40", soundVolume);}
        case 60: { prefmenu.AddItem("drand_pref_volume_50", soundVolume);}
        case 70: { prefmenu.AddItem("drand_pref_volume_60", soundVolume);}
        case 80: { prefmenu.AddItem("drand_pref_volume_70", soundVolume);}
        case 90: { prefmenu.AddItem("drand_pref_volume_80", soundVolume);}
        case 100: { prefmenu.AddItem("drand_pref_volume_90", soundVolume);}
        default: { prefmenu.AddItem("drand_pref_volume_100", soundVolume);}
    }
    prefmenu.ExitBackButton = true;
    prefmenu.Display(client, MENU_TIME_FOREVER);
}

public int SoundSettingHandler(Menu prefmenu, MenuAction actions, int client, int item)
{
    SetGlobalTransTarget(client);
    if (actions == MenuAction_Select)
    {
        char preference[32];
        GetMenuItem(prefmenu, item, preference, sizeof(preference));
        if(StrEqual(preference, "drand_pref_disable"))
        {
            g_bPlayerSoundDisabled[client] = !g_bPlayerSoundDisabled[client];
            SetClientCookie(client, g_hSoundToggleCookie, g_bPlayerSoundDisabled[client] ? "1" : "0");
        }
        if(StrContains(preference, "drand_pref_volume_") >= 0)
        {
            ReplaceString(preference, sizeof(preference), "drand_pref_volume_", "");
            int val = StringToInt(preference);
            g_fPlayerSoundVolume[client] = float(val) / 100;
            char buff[6];
            FloatToString(g_fPlayerSoundVolume[client], buff, sizeof(buff));
            SetClientCookie(client, g_hSoundVolumeCookie, buff);
        }
        DisplaySettingsMenu(client);
    }
    else if (actions == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack)
        {
            ShowCookieMenu(client);
        }
    }
    else if (actions == MenuAction_End)
    {
        CloseHandle(prefmenu);
    }
    return 0;
}

public void SoundSettingsMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen)
{
    if (actions == CookieMenuAction_DisplayOption)
    {
        Format(buffer, maxlen, "Difficulty Randomizer");
    }
    
    if (actions == CookieMenuAction_SelectOption)
    {
        DisplaySettingsMenu(client);
    }
}

bool IsOnlyDicimal(char[] string) {
    for(int i = 0; i < strlen(string); i++) {
        if (!IsCharNumeric(string[i])) {
            return false;
        }
    }
    return true;
}