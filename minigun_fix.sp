#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool g_bLateLoad;

public Plugin myinfo =
{
    name =          "[L4D/2] Minigun fix",
    author =        "Accelerator, Dosergen",
    description =   "Minigun fix",
    version =       "1.1",
    url =           "https://forums.alliedmods.net/showthread.php?p=2537610"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (g_bLateLoad) 
	{
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i)) 
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
}

public Action OnPreThink(int client)
{
	int ibuttons = GetClientButtons(client);
	if (( ibuttons & IN_USE ) && ( ibuttons & IN_JUMP ))
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hUseEntity");
		if (entity < 1)
			return Plugin_Continue;
		if (!IsValidEdict(entity))
			return Plugin_Continue;
	
		char classname[24];
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if (StrEqual(classname, "prop_minigun") || StrEqual(classname, "prop_minigun_l4d1") || StrEqual(classname, "prop_mounted_machine_gun"))
		{
			ibuttons &= ~IN_JUMP;
			SetEntProp(client, Prop_Data, "m_nButtons", ibuttons);
			
			float fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
			ScaleVector(fVelocity, GetRandomFloat(0.45, 0.72));
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
			
			SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil", GetGameTime() + 0.4);
		}
	}
	return Plugin_Continue;
}