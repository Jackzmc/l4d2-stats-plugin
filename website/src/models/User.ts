import db from "@/db/pool.ts";
import cache from '@/db/cache.ts'
import type { RowDataPacket } from "mysql2";
import type { Player } from "@/db/types.ts";
import assert from "assert";

export interface LeaderboardEntry {
    steamid: string,
    last_alias: string,
    minutes_played: number,
    last_join_date: number,
    points: number
}

export type PlayerWithPoints = Player & { points: number }

/**
 * Selects a random player of the day. Response is cached. Only returns players with points
 */
export async function getPlayerOfDay(): Promise<PlayerWithPoints> {
    const date = new Date()
    const cacheObj = await cache.get(`user.getPlayerOfDay.${date.getDate()}`)
    if(cacheObj) return cacheObj

    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT steamid, last_alias name, points 
        FROM stats_users 
        WHERE points > 0 
        ORDER BY RAND() 
        LIMIT 1`)
    assert(rows.length > 0, "no players in table")
    const playerOfDay = rows[0] as PlayerWithPoints

    // Calculate expire date for cache
    const nextDate = new Date()
    nextDate.setDate(date.getDate() + 1)
    const expires = nextDate.valueOf() - date.valueOf() + 1

    cache.set(`user.getPlayerOfDay.${date.getDate()}`, playerOfDay, expires)
    
    return playerOfDay
}

export interface PlayerTotals {
    /** The complete number of players in table */
    allPlayers: number,
    /** The number of players who have points > 0 */
    withPoints: number
}
/**
 * Returns the number of players in the users table with poion
 */
export async function getTotalPlayers(period: string): Promise<PlayerTotals> {
    const cacheObj = await cache.get("user.getTotalPlayers")
    if(cacheObj) return cacheObj

    const [rows] = await db.execute<RowDataPacket[]>(`SELECT
        (SELECT COUNT(*) FROM stats_users) allPlayers,
        (SELECT COUNT(*) FROM stats_users WHERE points > 0) withPoints
    `)
    const totals = {
        allPlayers: Number(rows[0].allPlayers),
        withPoints: Number(rows[0].withPoints)
    }
    cache.set("user.getTotalPlayers", totals, 1000 * 60 * 60) // 1 hr
    return totals
}

/**
 * Fetches list of players sorted descendingly by points.
 * @param page the current page - default 1
 * @param itemsPerPage number of items to return, default 30
 */
export async function getLeaderboards(page: number = 1, itemsPerPage = 30): Promise<LeaderboardEntry[]> {
    const offset = (page - 1) * itemsPerPage;
    const [entries] = await db.execute<(LeaderboardEntry & RowDataPacket)[]>(`SELECT
        steamid,last_alias,minutes_played,last_join_date,
        points as points
        FROM stats_users
        WHERE points > 0
        ORDER BY points desc
        LIMIT ?,?`, 
        [offset, itemsPerPage]
    )
    //        // (
        //     (common_kills / 1000 * 0.10) +
        //     (kills_all_specials * 0.25) +
        //     (revived_others * 0.05) +
        //     (heal_others * 0.05) -
        //     (survivor_incaps * 0.10) -
        //     (survivor_deaths * 0.05) +
        //     (survivor_ff * 0.03) +
        //     (damage_to_tank*0.15/minutes_played) +
        //     ((kills_molotov+kills_pipe)*0.025) +
        //     (witches_crowned*0.2) -
        //     (rocks_hitby*0.2) +
        //     (cleared_pinned*0.05)
        // ) as points_new_old
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
    const cacheObj = await cache.get("user.getUser." + steamid)
    if(cacheObj) return cacheObj

    const [rows] = await db.execute<RowDataPacket[]>("SELECT * FROM stats_users WHERE SUBSTRING(steamid, 11) = SUBSTRING(?, 11)", [steamid])
    if(rows.length === 0) return null

    cache.set("user.getUser." + steamid, rows[0], 1000 * 60 * 5)
    return rows[0] as any
} 

interface TopStat {
    value: string,
    id?: string
    count: number,
}
export interface UserTopStats extends Player {
    top_weapon: TopStat,
    top_char: TopStat,
    top_map: TopStat,
    played_official: TopStat,
    played_custom: TopStat,
    played_any: TopStat
}
export async function getUserTopStats(steamid: string): Promise<UserTopStats | null> {
    const cacheObj = await cache.get("user.getUserTopStats." + steamid)
    if(cacheObj) return cacheObj
    // TODO: support top_map being non-official maps? (need to worry about anything calling getMapScreenshot such as banner.png.ts)
    const [rows] = await db.execute<RowDataPacket[]>(`
        (SELECT 'top_weapon' name, top_weapon id, w.name value, COUNT(*) count FROM stats_games g LEFT JOIN weapon_names w ON w.id = g.top_weapon WHERE steamid = :steamid AND top_weapon != '' GROUP BY top_weapon ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'top_char' name, '' id, characterType value, COUNT(*) count FROM stats_games WHERE steamid = :steamid AND characterType IS NOT NULL GROUP BY characterType ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'top_map' name, map id, i.name value, COUNT(*) count FROM stats_games g LEFT JOIN map_info i ON i.mapid = g.map WHERE steamid = :steamid AND map LIKE 'c%m%_%' GROUP BY map ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'played_official' name, '' id, '' value, COUNT(*) count FROM stats_games WHERE steamid = :steamid AND map LIKE 'c%m%_%' ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'played_custom' name, '' id, '' value, COUNT(*) count FROM stats_games WHERE steamid = :steamid AND map NOT LIKE 'c%m%_%' ORDER BY count DESC LIMIT 1)
        UNION ALL
        (SELECT 'played_any' name, '' id, '' value, COUNT(*) count FROM stats_games WHERE steamid = :steamid LIMIT 1)`,
        { steamid }
    )
    if(rows.length === 0) return null
    const out: Record<string, TopStat> = {}
    for(const row of rows) {
        out[row.name] = {
            id: row.id,
            value: row.value,
            count: row.count
        }
    }
    cache.set("user.getUserTopStats." + steamid, out, 1000 * 60 * 5) // 5 min
    return out as unknown as UserTopStats
}

export type PlayerSearchResult = Player & { minutes_played: number, last_join_date: number, points: number }
/**
 * Search for users
 * @param query steamid or name
 * @param limit number of users to return
 */
export async function searchUsers(query: string, limit = 20): Promise<PlayerSearchResult[]> {
    query = `%${query}%`
    const [rows] = await db.execute<RowDataPacket[]>(
        "SELECT steamid, last_alias name, minutes_played, last_join_date, points FROM stats_users WHERE steamid LIKE :query OR last_alias LIKE :query ORDER BY points DESC LIMIT :limit",
        { query, limit }
    )

    return rows.map(row => {
        return {
            steamid: row.steamid,
            name: row.name,
            minutes_played: row.minutes_played,
            last_join_date: row.last_join_date,
            points: row.points
        }
    })
}

export interface WeaponStat {
    id: string,
    name: string,
    melee?: boolean,
    minutesUsed: number,
    totalDamage: number,
    headshots: number,
    kills: number
}

export async function getUserWeapons(steamid: string): Promise<WeaponStat[]> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT weapon id,n.name name,n.melee, minutesUsed,totalDamage,headshots,kills
        FROM stats_weapons_usage
        RIGHT JOIN weapon_names n ON n.id = weapon 
        WHERE steamid = ?
        ORDER BY totalDamage DESC, kills DESC
    `, [steamid])

    return rows.map(row => {
        return {
            id: row.id,
            name: row.name ?? row.id,
            melee: Boolean(row.melee),
            minutesUsed: Number(row.minutesUsed),
            totalDamage: Number(row.totalDamage),
            headshots: Number(row.headshots),
            kills: Number(row.kills)
        }
    })
}