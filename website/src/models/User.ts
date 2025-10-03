import type { RowDataPacket } from "mysql2";
import db from "../db/pool.ts";
import type { StatsUsersEntity } from "../db/types.ts";

export interface LeaderboardEntry {
    user_steamid: string,
    user_name: string,
    minutes_played: number,
    last_join_date: number,
    points: number
}

/**
 * Fetches list of players sorted descendingly by points.
 * @param page page offset, default 0
 * @param itemsPerPage number of items to return, default 30
 */
export async function getLeaderboard(page: number = 0, itemsPerPage = 30): Promise<LeaderboardEntry[]> {
    const offset = page * itemsPerPage;

    const [rows] = await db.query<(LeaderboardEntry & RowDataPacket)[]>(`select
        steamid,last_alias,minutes_played,last_join_date,
        points as points_old,
        (
            (common_kills / 1000 * 0.10) +
            (kills_all_specials * 0.25) +
            (revived_others * 0.05) +
            (heal_others * 0.05) -
            (survivor_incaps * 0.10) -
            (survivor_deaths * 0.05) +
            (survivor_ff * 0.03) +
            (damage_to_tank*0.15/minutes_played) +
            ((kills_molotov+kills_pipe)*0.025) +
            (witches_crowned*0.2) -
            (rocks_hitby*0.2) +
            (cleared_pinned*0.05)
        ) as points
        from stats_users
        order by points desc
        limit ?,?`, 
        [offset, itemsPerPage]
    )
    return rows
}