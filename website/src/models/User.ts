import type { RowDataPacket } from "mysql2";
import db from "@/db/pool.ts";
import type { Player, StatsUsersEntity } from "@/db/types.ts";
import assert from "assert";

export interface LeaderboardEntry {
    steamid: string,
    last_alias: string,
    minutes_played: number,
    last_join_date: number,
    points: number
}

export type PlayerWithPoints = Player & { points: number }
let playerOfDay: { player: PlayerWithPoints, timestamp: Date } | null = null

/**
 * Selects a random player of the day. Response is cached. Only returns players with points
 */
export async function getPlayerOfDay(): Promise<PlayerWithPoints> {
    const date = new Date()
    if(!playerOfDay || playerOfDay.timestamp.getDate() != date.getDate()) {
        const [rows] = await db.execute<RowDataPacket[]>(`
            SELECT steamid, last_alias name, points 
            FROM stats_users 
            WHERE points > 0 
            ORDER BY RAND() 
            LIMIT 1`)
        assert(rows.length > 0, "no players in table")
        playerOfDay = {
            player: rows[0] as PlayerWithPoints,
            timestamp: date
        }
    }
    
    return playerOfDay.player
}

/**
 * Returns the number of players in the users table
 */
export async function getTotalPlayers(): Promise<number> {
    const [countRow] = await db.execute<RowDataPacket[]>("SELECT COUNT(*) count FROM stats_users")
    return countRow[0].count
}

/**
 * Fetches list of players sorted descendingly by points.
 * @param page the current page - default 1
 * @param itemsPerPage number of items to return, default 30
 */
export async function getLeaderboards(page: number = 1, itemsPerPage = 30): Promise<LeaderboardEntry[]> {
    const offset = (page - 1) * itemsPerPage;
    const [entries] = await db.execute<(LeaderboardEntry & RowDataPacket)[]>(`select
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
    return entries
}

export async function getUser(steamid: string): Promise<any | null> {
    const [rows] = await db.execute<RowDataPacket[]>("SELECT * FROM stats_users WHERE SUBSTRING(steamid, 11) = SUBSTRING(?, 11)", [steamid])
    if(rows.length === 0) return null
    return rows[0] as any
} 