Menu g_rateMenu;

Menu SetupRateMenu() {
	Menu menu = new Menu(MapVoteHandler);
	menu.SetTitle("Rate Map");
	menu.AddItem("1", "1 stars (Bad)");
	menu.AddItem("2", "2 stars");
	menu.AddItem("3", "3 stars");
	menu.AddItem("4", "4 stars");
	menu.AddItem("5", "5 stars (Good)");
	menu.ExitButton = true;
	return menu;
}

int MapVoteHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		static char info[2];
		menu.GetItem(param2, info, sizeof(info));
		int value = StringToInt(info);
		if(g_players[param1].user.steamid[0] == '\0') return 0;
		
		SubmitMapRating(param1, value);
	} else if (action == MenuAction_End) {
		// Don't delete, shared menu
	} 
	return 0;
}



Action Command_RateMap(int client, int args) {
	if(!L4D_IsMissionFinalMap()) {
		ReplyToCommand(client, "Can only rate on map finales");
		return Plugin_Handled;
	}
	if(args == 0) {
		g_rateMenu.SetTitle("Rate %s", game.mapTitle);
		g_rateMenu.Display(client, 0);
	} else {
		char arg[255];
		GetCmdArg(1, arg, sizeof(arg));
		int value = StringToInt(arg);
		if(value <= 0 || value > 5) {
			ReplyToCommand(client, "Invalid rating, must be between 1 (low) and 5 (high). Syntax: /rate <1-5>");
			return Plugin_Handled;
		} 
		if(args > 1) {
			if(GetUserAdmin(client) == INVALID_ADMIN_ID) {
				ReplyToCommand(client, "Only server admins can add comments with their rating. Syntax: /rate <1-5>");
				return Plugin_Handled;
			}
			GetCmdArg(2, arg, sizeof(arg));
		}

		SubmitMapRating(client, value, arg);
	}
	return Plugin_Handled;
}



void SubmitMapRating(int client, int rating, const char[] comment = "") {
	char query[1024];
	g_db.Format(query, sizeof(query), "INSERT INTO stats_map_ratings (map_id,steamid,value,comment) VALUES ('%s','%s',%d,'%s') ON DUPLICATE KEY UPDATE value = %d, comment = '%s'",
		game.mapId,
		g_players[client].user.steamid,
		rating,
		comment,
		rating,
		comment
	);
	g_db.Query(DBCT_RateMap, query, GetClientUserId(client));
}
