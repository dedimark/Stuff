#define PLUGIN_VERSION "1.1"

/*
 * ============================================================================
 *
 *  Description:	Prevents people from blocking players who climb on the ladder.
 *
 *  Credits:		Original code taken from Rotoblin2 project
 *					written by Me and ported to l4d2.
 *					See rotoblin.ExpolitFixes.sp module
 *
 *	Site:			http://code.google.com/p/rotoblin2/
 *
 *  Copyright (C) 2012 raziEiL <war4291@mail.ru>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar g_hCvarFlags, g_hCvarImmune;
static int g_iCvarFlags, g_iCvarImmune;
bool g_bLoadLate;

public Plugin myinfo =
{
	name = "[L4D] No Ladder Block",
	author = "raziEiL [disawar1]",
	description = "Prevents people from blocking players who climb on the ladder.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only support L4D engine");
		return APLRes_Failure;
	}

	g_bLoadLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_ladderblock_version", PLUGIN_VERSION, "No Ladder Block plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarFlags = CreateConVar("l4d_ladderblock_flags", "110", "Who can push trolls when climbs on the ladder. Flags (add together): 0=Disable, 2=Smoker, 4=Boomer, 8=Hunter, 32=Tank, 64=Survivors, 110=All", 0, true, 0.0, true, 110.0);
	g_hCvarImmune = CreateConVar("l4d_ladderblock_immune", "0", "What class is immune. Flags (add together): 0=Disable, 2=Smoker, 4=Boomer, 8=Hunter, 32=Tank, 64=Survivors, 110=All", 0, true, 0.0, true, 110.0);

	AutoExecConfig(true, "l4d_ladderblock");

	g_iCvarFlags = g_hCvarFlags.IntValue;
	g_iCvarImmune = g_hCvarImmune.IntValue;

	g_hCvarFlags.AddChangeHook(OnCvarChange_Flags);
	g_hCvarImmune.AddChangeHook(OnCvarChange_Immune);
	
	if (g_iCvarFlags && g_bLoadLate)
	{
		LB_ToogleHook(true);
	}
}

public void OnClientPutInServer(int client)
{
    if (g_iCvarFlags && client)
	{
		SDKHook(client, SDKHook_Touch, SDKHook_cb_Touch);
	}
}

public void SDKHook_cb_Touch(int entity, int other)
{
	if (other > MaxClients || other < 1) 
	{
		return;
	}

	if (IsGuyTroll(entity, other))
	{
		int iClass = GetEntProp(entity, Prop_Send, "m_zombieClass");

		if (g_iCvarFlags & (1 << iClass))
		{
			iClass = GetEntProp(other, Prop_Send, "m_zombieClass");

			if (g_iCvarImmune & (1 << iClass))
			{
				return;
			}

			if (IsOnLadder(other))
			{
				float vOrg[3];
				GetClientAbsOrigin(other, vOrg);
				vOrg[2] += 2.5;
				TeleportEntity(other, vOrg, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 251.0}));
			}
		}
	}
}

bool IsGuyTroll(int victim, int troll)
{
	return IsOnLadder(victim) && GetClientTeam(victim) != GetClientTeam(troll) && GetEntPropFloat(victim, Prop_Send, "m_vecOrigin[2]") < GetEntPropFloat(troll, Prop_Send, "m_vecOrigin[2]");
}

bool IsOnLadder(int entity)
{
	return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}

void LB_ToogleHook(bool bHook)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) 
		{
			continue;
		}

		if (bHook)
		{
			SDKHook(i, SDKHook_Touch, SDKHook_cb_Touch);
		}
		else
		{
			SDKUnhook(i, SDKHook_Touch, SDKHook_cb_Touch);
		}
	}
}

public void OnCvarChange_Flags(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue)) 
	{
		return;
	}

	g_iCvarFlags = GetConVarInt(convar);

	if (!StringToInt(oldValue))
	{
		LB_ToogleHook(true);
	}
	else if (!g_iCvarFlags)
	{
		LB_ToogleHook(false);
	}
}

public void OnCvarChange_Immune(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(oldValue, newValue))
	{
		g_iCvarImmune = GetConVarInt(convar);
	}
}