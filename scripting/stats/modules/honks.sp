ConVar hClownMode, hPopulationClowns, hMinShove, hMaxShove, hClownModeChangeChance;
static Handle hHonkCounterTimer;

void CVC_ClownModeChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	hPopulationClowns = FindConVar("l4d2_population_clowns");
	if(hPopulationClowns == null) {
		PrintToServer("[Stats] ERROR: Missing plugin for clown mode");
		return;
	}
	if(hClownMode.IntValue > 0) {
		hMinShove.IntValue = 20;
		hMaxShove.IntValue = 40;
		hPopulationClowns.FloatValue = 0.4;
		hHonkCounterTimer = CreateTimer(15.0, Timer_HonkCounter, _, TIMER_REPEAT);
	} else {
		hMinShove.IntValue = 5;
		hMaxShove.IntValue = 15;
		hPopulationClowns.FloatValue = 0.0;
		if(hHonkCounterTimer != null) {
			delete hHonkCounterTimer;
		}
	}
}
Action Timer_HonkCounter(Handle h) { 
	int honks, honker = -1;
	for(int j = 1; j <= MaxClients; j++) {
		if(players[j].clownsHonked > 0 && (players[j].clownsHonked > honks || honker == -1) && !IsFakeClient(j)) {
			honker = j;
			honks = players[j].clownsHonked;
		}
	}
	if(honker > 0) {
		for(int i = 1; i <= MaxClients; i++) {
			if(players[i].clownsHonked > 0 && IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
				PrintHintText(i, "Top Honker: %N (%d honks)\nYou: %d honks", honker, honks, players[i].clownsHonked);
			}
		}
	}
	if(hClownMode.IntValue == 2 && GetURandomFloat() < hClownModeChangeChance.FloatValue) {
		if(GetRandomFloat() > 0.6)
			hPopulationClowns.FloatValue = 0.0;
		else 
			hPopulationClowns.FloatValue = GetRandomFloat();
		PrintToConsoleAll("Honk Mode: New population %.0f%%", hPopulationClowns.FloatValue * 100);
	}
	return Plugin_Continue; 
}