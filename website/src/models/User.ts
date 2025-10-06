import type { RowDataPacket } from "mysql2";
import db from "@/db/pool.ts";
import type { Player, StatsUsersEntity } from "@/db/types.ts";
import assert from "assert";
import type { Survivor } from "@/types/game.ts";
import type { GameSessionPartial } from "./Game.ts";

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

export interface PlayerFull {
  steamid: string;
  last_alias: string;
  last_join_date: number;
  created_date: number;
  connections: number;
  country: string;
  region: string;
  points: number;
  survivor_deaths: number;
  infected_deaths: number;
  survivor_damage_rec: number;
  survivor_damage_give: number;
  infected_damage_rec: number;
  infected_damage_give: number;
  pickups_molotov: number;
  pickups_pipe_bomb: number;
  survivor_incaps: number;
  pills_used: number;
  defibs_used: number;
  adrenaline_used: number;
  heal_self: number;
  heal_others: number;
  revived: number;
  revived_others: number;
  pickups_pain_pills: number;
  melee_kills: number;
  tanks_killed: number;
  tanks_killed_solo: number;
  tanks_killed_melee: number;
  survivor_ff: number;
  survivor_ff_rec: null;
  common_kills: number;
  common_headshots: number;
  door_opens: number;
  damage_to_tank: number;
  damage_as_tank: number;
  damage_witch: number;
  minutes_played: number;
  finales_won: number;
  kills_smoker: number;
  kills_boomer: number;
  kills_hunter: number;
  kills_spitter: number;
  kills_jockey: number;
  kills_charger: number;
  kills_witch: number;
  packs_used: number;
  ff_kills: number;
  throws_puke: number;
  throws_molotov: number;
  throws_pipe: number;
  damage_molotov: number;
  kills_molotov: number;
  kills_pipe: number;
  kills_minigun: number;
  caralarms_activated: number;
  witches_crowned: number;
  witches_crowned_angry: number;
  smokers_selfcleared: number;
  rocks_hitby: number;
  hunters_deadstopped: number;
  cleared_pinned: number;
  times_pinned: number;
  clowns_honked: number;
  minutes_idle: number;
  boomer_mellos: number;
  boomer_mellos_self: number;
  forgot_kit_count: number;
  total_distance_travelled: number;
  kills_all_specials: number;
  kits_slapped: number;
}
export async function getUser(steamid: string): Promise<PlayerFull | null> {
    const [rows] = await db.execute<RowDataPacket[]>("SELECT * FROM stats_users WHERE SUBSTRING(steamid, 11) = SUBSTRING(?, 11)", [steamid])
    if(rows.length === 0) return null
    return rows[0] as any
} 

interface TopStat {
    value: string,
    count: number
}
export interface UserTopStats extends Player {
    top_weapon: TopStat,
    top_char: TopStat,
    top_map: TopStat,
    played_official: TopStat,
    played_custom: TopStat
}
export async function getUserTopStats(steamid: string): Promise<UserTopStats | null> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        (SELECT 'top_weapon' name, top_weapon value, COUNT(*) count FROM stats_games WHERE steamid = :steamid AND top_weapon != '' GROUP BY top_weapon ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'top_char' name, characterType value, COUNT(*) count FROM stats_games WHERE steamid = :steamid AND characterType IS NOT NULL GROUP BY characterType ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'top_map' name, map value, COUNT(*) count FROM stats_games WHERE steamid = :steamid GROUP BY map ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'played_official' name, '' value, COUNT(*) count FROM stats_games WHERE steamid = :steamid AND map LIKE 'c%m%_%' ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'played_custom' name, '' value, COUNT(*) count FROM stats_games WHERE steamid = :steamid AND map NOT LIKE 'c%m%_%' ORDER BY count DESC LIMIT 1)`,
        { steamid }
    )
    if(rows.length === 0) return null
    const out: Record<string, TopStat> = {}
    for(const row of rows) {
        out[row.name] = {
            value: row.value,
            count: row.count
        }
    }
    return out as unknown as UserTopStats
}

export async function getCounts(steamid: string): Promise<{ games_played: number } | null> {
    const [rows] = await db.execute<RowDataPacket[]>(
        `SELECT COUNT(*) games_played FROM stats_games WHERE SUBSTRING(steamid, 11) = SUBSTRING(?, 11)`, 
        [steamid]
    )
    if(rows.length === 0) return null
    return {
        games_played: rows[0].games_played
    }
}