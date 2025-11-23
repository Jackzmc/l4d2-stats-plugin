Action Timer_CalculateDistances(Handle h) {
	if(game.finished) return Plugin_Continue;

	for(int i=1; i<= MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && g_players[i].user.steamid[0]) {
			MoveType moveType = GetEntityMoveType(i);
			if(moveType != MOVETYPE_WALK && moveType != MOVETYPE_LADDER) continue;
			g_players[i].MeasureDistance(i);
		}
	}
	return Plugin_Continue;
}
