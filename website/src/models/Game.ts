import db from '@/db/pool.ts'
import cache from '@/db/cache.ts'
import type { RowDataPacket } from 'mysql2';
import { QueryConditionBuilder } from '@/db/helpers.ts';
import type { Difficulty, Survivor } from '@/types/game.ts';
import type { Player } from '@/db/types.ts';

export interface RecentGame {
  num_players: number;
  campaign_id: string;
  map_id: string;
  map_name: string;
  date_end: number;
  duration_mins: number;
  difficulty: number;
  gamemode: string;
  kills_common: string;
  damage_dealt_friendly_count: string;
  deaths: string;
  used_kit_self: string;
  used_throwables: string;
  tags: string[];
}

/**
 * Returns count amount of recently played games
 * @param count number of games to return
 * @returns Game with some sums and game info
 */
export async function getRecentGames(page: number = 1, limit = 8): Promise<RecentGame[]> {
    const offset = (page - 1) * limit
    // const [total] = await db.execute("SELECT COUNT(DISTINCT campaignID) as total FROM `stats_games`")
    const [recents] = await db.execute<RowDataPacket[]>(`
        SELECT
            g.uuid campaign_id,
            g.map_id map_id,
            i.name as map_name,
            g.date_end date_end,
            COUNT(*) as num_players,
            (g.duration_game / 60) duration_mins,
            difficulty,
            gamemode,
            SUM(kills_common) as kills_common,
            SUM(damage_dealt_friendly_count) as damage_dealt_friendly_count,
            SUM(deaths) as deaths,
            SUM(used_kit_self) as used_kit_self,
            (SUM(used_molotov) + SUM(used_pipebomb) + SUM(used_bile)) as used_throwables,
            server_tags tags
        FROM stats_sessions as s
        JOIN stats_games g ON g.id = s.game_id
        LEFT JOIN stats_map_info i ON i.mapid = g.map_id
        GROUP BY g.id
        ORDER BY g.date_end DESC
        LIMIT ?, ?
    `, [offset, limit])

    return recents.map((row,i) => {
        return {
            ...row,
            duration_mins: Math.round(row.duration_mins),
            tags: row.tags.split(",")
        } as RecentGame
    })
}


interface FilterOptions { steamid?: string, gamemode?: string|null, difficulty?: number|null, map_type?: number|null, tag?: string|null, map?: string|null }
/**
 * Returns count amount of recently played games
 * @param limit number of games to return
 * @returns Game with some sums and game info
 */
export async function getFilteredGames(opts: FilterOptions = {}, page = 1, limit = 8): Promise<RecentGame[]> {
    if(page < 1) page = 1
    const offset = (page - 1) * limit

    // const [total] = await db.execute("SELECT COUNT(DISTINCT campaignID) as total FROM `stats_games`")
    const builder = new QueryConditionBuilder()
    if(opts.gamemode) builder.push("gamemode = ?", opts.gamemode)
    if(opts.difficulty != undefined) builder.push("difficulty = ?", opts.difficulty)
    if(opts.map_type) builder.push("i.flags = ?", opts.map_type)
    if(opts.tag) builder.push("FIND_IN_SET(?, server_tags)", opts.tag)
    if(opts.map) builder.push("map LIKE ?", `${opts.map}%`)
    if(opts.steamid) builder.push("steamid = ?", opts.steamid)

    const [whereClause, data] = builder.buildFullWhere()

    const [games] = await db.execute<RowDataPacket[]>(`
        SELECT
            g.uuid campaign_id,
            g.map_id map_id,
            i.name as map_name,
            g.date_end date_end,
            COUNT(*) as num_players,
            (g.duration_game / 60) duration_mins,
            difficulty,
            gamemode,
            SUM(kills_common) as kills_common,
            SUM(damage_dealt_friendly_count) as damage_dealt_friendly_count,
            SUM(deaths) as deaths,
            SUM(used_kit_self) as used_kit_self,
            (SUM(used_molotov) + SUM(used_pipebomb) + SUM(used_bile)) as used_throwables,
            server_tags tags
        FROM stats_sessions as s
        JOIN stats_games g ON g.id = s.game_id
        LEFT JOIN stats_map_info i ON i.mapid = g.map_id
        ${whereClause}
        GROUP BY g.id
        ORDER BY g.date_end DESC
        LIMIT ?, ?
    `, [...data, offset, limit])

    return games.map((row,i) => {
        return {
            ...row,
            duration_mins: Math.round(row.duration_mins),
            tags: row.tags.split(",")
        } as RecentGame
    })
}

export interface Game {
    id: number
    uuid: string;
    map_id: string;
    map_name: string,
    difficulty: Difficulty,
    gamemode: string,
    date: number;
    duration_game: number;
    duration_finale: number;
    server_tags: string[];
    kills_all_specials: number;
    commons_killed: number;
    honks: number;
    used_kit: number;
    used_pills: number,
    used_adrenaline: number,
    used_bile: number;
    used_pipebomb: number;
    used_molotov: number;
    times_incapped: number;
    deaths: number;
    damage_dealt: number;
    damage_taken: number;
}

/**
 * Returns game data, with sums of some its sessions' stats
 * @param id gamei d
 * @returns 
 */
export async function getGame(id: string): Promise<Game | null> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT i.mapid map_id, i.name as map_name, 
            g.difficulty difficulty, g.gamemode gamemode, 
            g.date_end date, 
            g.server_tags, 
            g.duration_finale, g.duration_game,
            g.id,
            g.uuid,
            SUM(s.kills_all_specials) kills_all_specials,
            SUM(s.kills_common) commons_killed,
            SUM(s.honks) honks,
            SUM(s.used_kit) used_kit,
            SUM(s.used_pills) used_pills,
            SUM(s.used_adrenaline) used_adrenaline,
            SUM(s.used_bile) used_bile,
            SUM(s.used_pipebomb) used_pipebomb,
            SUM(s.used_molotov) used_molotov,
            SUM(s.times_incapped) times_incapped,
            SUM(s.deaths) deaths,
            SUM(s.damage_dealt) damage_dealt,
            SUM(s.damage_taken) damage_taken
        FROM stats_games g
        LEFT JOIN stats_sessions s ON s.game_id = g.id
        JOIN stats_map_info i ON i.mapid = g.map_id
        WHERE left(g.uuid, 8) = ? OR CAST(g.id as CHAR) = ?
        LIMIT 1
    `, [id.substring(0, 8), id])
    // row[0] will exist due to use of AVG(), check for null map:
    if(rows.length === 0 || !rows[0].map_id) return null
    return {
        ...rows[0],
        // Prevent empty string turning into [""]
        server_tags: rows[0].server_tags.length > 0 ? rows[0].server_tags.split(",") : []
    } as Game
}

export interface GameSessionPartial extends Player {
  id: number;
  game_id: number,
  game_uuid: string,
  points: number;
  flags: number;
  character_type: Survivor;
  kills_common: number;
  kills_melee: number;
  damage_dealt_friendly_count: number;
  damage_dealt_tank: number,
  damage_dealt_witch: number,
  used_kit_self: number;
  used_pills: number;
  used_molotov: number;
  used_pipebomb: number;
  used_bile: number;
  used_adrenaline: number;
  damage_taken: number;
  times_incapped: number;
  deaths: number;
  kills_all_specials: number;
  honks: number;
  rocks_dodged: number,
  rocks_hitby: number,
  times_revived_other: number,
  used_kit_other: number
}

/**
 * Returns list of sessions for a game, with partial data of each session
 * @param id game id
 * @returns 
 */
export async function getSessions(id: string): Promise<GameSessionPartial[]> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT s.id,
            s.steamid,
            u.last_alias name,
            points,
            flags,
            character_type,
            s.kills_common,
            s.damage_dealt_friendly_count,
            s.damage_dealt_tank,
            s.damage_dealt_witch,
            s.used_kit_self,
            s.used_pills,
            s.used_molotov,
            s.used_pipebomb,
            s.used_bile,
            s.used_adrenaline,
            s.damage_taken,
            s.times_incapped,
            s.deaths,
            s.kills_all_specials,
            s.honks,
            s.caralarms_activated,
            s.rocks_hitby,
            s.rocks_dodged,
            s.times_revived_other,
            s.used_kit_other
        FROM stats_sessions s
        INNER JOIN stats_users u ON u.steamid = s.steamid
        LEFT JOIN stats_games g ON g.id = s.game_id
        WHERE left(g.uuid, 8) = ? OR CAST(g.id as CHAR) = ?
        ORDER BY s.kills_all_specials desc, s.damage_dealt_friendly_count asc, s.kills_common desc, s.damage_taken asc
    `, [id.substring(0,8), id]
    )

    return rows as GameSessionPartial[]
}

export interface GameSession extends GameSessionPartial {
    map_id: string,
    map_name: string,
    gamemode: string,
    difficulty: Difficulty,
    server_tags: string[],
    join_time: number,
    ping: number,
    duration_game: number,
    date_start: number,
    date_end: number,
    damage_dealt: number,
    damage_dealt_friendly: number,
    damage_dealt_friendly_count: number,
    damage_taken: number,
    damage_taken_friendly: number,
    damage_taken_friendly_count: number,
    damage_dealt_tank: number,
    damage_dealt_witch: number,
    used_kit: number,
    used_kit_self: number,
    used_kit_other: number,
    used_defib: number,
    times_revived_other: number,
    times_incapped: number,
    kills_melee: number,
    kills_common: number,
    kills_boomer: number,
    kills_smoker: number,
    kills_charger: number,
    kills_jockey: number,
    kills_hunter: number,
    kills_spitter: number,
    kills_tank: number,
    kills_witch: number,
    top_weapon: string,
    seconds_alive: number,
    seconds_idle: number,
    seconds_dead: number,
    seconds_total: number,
    witches_crowned: number,
    smokers_selfcleared: number,
    rocks_hitby: number,
    rocks_dodged: number,
    hunters_deadstopped: number,
    times_pinned: number,
    times_cleared_pinned: number,
    times_boomed_teammates: number,
    times_boomed: number,
    caralarms_activated: number,
    longest_shot_distance: number
}

/**
 * Returns full session info, including user, tags, gamemode, etc
 */
export async function getSession(id: number | string): Promise<GameSession | null> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT s.id,
            s.game_id game_id,
            g.uuid game_uuid,
            s.steamid,
            u.last_alias name,
            u.points,
            g.server_tags,
            g.map_id as map_id,
            i.name as map_name,
            g.gamemode,
            g.difficulty,
            g.duration_game,
            g.date_start,
            g.date_end,
            s.flags,
            s.join_time,
            s.character_type,
            s.ping,
            s.damage_dealt,
            s.damage_dealt_friendly,
            s.damage_dealt_friendly_count,
            s.damage_taken,
            s.damage_taken_friendly,
            s.damage_taken_friendly_count,
            s.damage_dealt_tank,
            s.damage_dealt_witch,
            s.used_kit,
            s.used_kit_self,
            s.used_kit_other,
            s.used_pills,
            s.used_molotov,
            s.used_pipebomb,
            s.used_bile,
            s.used_adrenaline,
            s.used_defib,
            s.times_revived_other,
            s.times_incapped,
            s.deaths,
            s.kills_common,
            s.kills_melee,
            s.kills_smoker,
            s.kills_boomer,
            s.kills_jockey,
            s.kills_hunter,
            s.kills_spitter,
            s.kills_charger,
            s.kills_all_specials,
            s.kills_tank,
            s.kills_witch,
            s.honks,
            s.top_weapon,
            s.witches_crowned,
            s.smokers_selfcleared,
            s.rocks_hitby,
            s.rocks_dodged,
            s.hunters_deadstopped,
            s.times_pinned,
            s.times_cleared_pinned,
            s.times_boomed_teammates,
            s.times_boomed,
            s.caralarms_activated,
            s.seconds_alive,
            s.seconds_idle,
            s.seconds_dead,
            s.seconds_total,
            s.longest_shot_distance
        FROM stats_sessions s
        LEFT JOIN stats_games g ON g.id = s.game_id
        INNER JOIN stats_users u ON s.steamid = u.steamid
        LEFT JOIN stats_map_info i ON g.map_id = i.mapid
        WHERE s.id = ?
        LIMIT 1
    `, [id]
    )
    if(rows.length === 0) return null
    return {
        ...rows[0],
        // Prevent empty string turning into [""]
        server_tags: rows[0].server_tags.length > 0 ? rows[0].server_tags.split(",") : [],
    } as GameSession
}

/**
 * Returns all players in a given game
 * @param id game id
 * @returns object[] -> { sessionId, steamid, playerName }[]
 */
export async function getSessionPlayers(id: string): Promise<(Player & { sessionId: number })[]> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT s.id sessionId, s.steamid, u.last_alias playerName
        FROM stats_sessions s
        LEFT JOIN stats_games g ON g.id = s.game_id
        INNER JOIN stats_users u ON u.steamid = s.steamid
        WHERE left(g.uuid, 8) = ? OR CAST(g.id AS CHAR) = ?
        order by g.date_end asc
    `, [id.substring(0,8), id])

    return rows.map(row => {
        return {
            sessionId: row.sessionId,
            steamid: row.steamid,
            name: row.playerName
        }
    })
}

/**
 * Returns list of all distinct gamemodes 
 * @returns string[]
 */
export async function getGamemodes(): Promise<string[]> {
    const cacheObj = await cache.get("game.getGamemodes")
    if(cacheObj) return cacheObj

    const [rows] = await db.execute<RowDataPacket[]>(
    "SELECT distinct gamemode FROM stats_games"
    )
    const list = rows.map(row => row.gamemode)
    cache.set("game.getGamemodes", list, 1000 * 60 * 5)
    return list
}
/**
 * Returns list of all distinct server tags 
 * @returns string[]
 */
export async function getServerTags(): Promise<string[]> {
    const cacheObj = await cache.get("game.getServerTags")
    if(cacheObj) return cacheObj
    const [rows] = await db.execute<RowDataPacket[]>(
    "SELECT distinct server_tags FROM stats_games WHERE server_tags != ''"
    )
    // rows returns unique combinations of tags, 
    // but we need to split by comma to get full list

    // count the number of occurrences of every tag
    const obj: Record<string, number> = {}
    const flatTags = rows
        // Prevent empty string turning into [""]
        .map(row => row.server_tags.length > 0 ? row.server_tags.split(",") : [])
        .flat()
    flatTags.forEach(tag => {
        if(!obj[tag]) obj[tag] = 0
        obj[tag]++
    })

    // return sorted list of all tags, in descending order by count
    const sortList = Object.entries(obj)
        .sort(([,val1],[,val2]) => val2 - val1)
        .map(([key]) => key);

    cache.set("game.getServerTags", sortList, 1000 * 60 * 5)

    return sortList
}

export interface Trait {
    steamid: string,
    name: string,
    stat: string,
    value: number
}

export async function getGameTraits(gameId: string, limit: number): Promise<Trait[]> {
    // TODO: calculate MVP from value https://app.plane.so/jackz/browse/SM-104/
    // TODO: add new game traits https://app.plane.so/jackz/browse/SM-105/
    // TODO: 
    const cacheObj = await cache.get("game.getGameTraits." + gameId)
    if(cacheObj) return cacheObj
    const [rows] = await db.execute<RowDataPacket[]>(`
    # load columns 
        WITH stats AS (
            SELECT s.steamid,
                u.last_alias name,
                s.rocks_dodged,
                s.rocks_hitby,
                s.damage_taken,
                s.kills_common,
                s.kills_all_specials,
                s.deaths,
                s.longest_shot_distance
            FROM stats_sessions s
            LEFT JOIN stats_games g ON g.id = s.game_id
            LEFT JOIN stats_users u ON s.steamid = u.steamid
            WHERE left(g.uuid, 8) = ? OR CAST(g.id AS CHAR) = ?
        ),
    # convert rows
        flattened AS (
            SELECT steamid, name, 'rocks_dodged' AS stat, rocks_dodged AS value FROM stats
            UNION ALL
            SELECT steamid, name, 'rocks_hitby', rocks_hitby FROM stats
            UNION ALL
            SELECT steamid, name, 'damage_taken', damage_taken FROM stats
            UNION ALL
            SELECT steamid, name, 'kills_common', kills_common FROM stats
            UNION ALL
            SELECT steamid, name, 'kills_all_specials', kills_all_specials FROM stats
            UNION ALL
            SELECT steamid, name, 'deaths', deaths FROM stats
            UNION ALL
            SELECT steamid, name, 'longest_shot_distance', longest_shot_distance FROM stats

        ),
    # rank them by max / min
        ranked AS (
            SELECT *,
                RANK() OVER (
                    PARTITION BY stat
                    ORDER BY
                        CASE WHEN stat = 'damage_taken' THEN value ELSE -value END
                ) AS r
            FROM flattened
            WHERE value > 0
        ),
    # get number of rows in top slot for stat
        top_counts AS (
            SELECT stat, COUNT(*) AS cnt
            FROM ranked
            WHERE r = 1
            GROUP BY stat
        )
    # filter out N amount, excluding any ties from results
        SELECT r.steamid, r.stat, r.name, r.value
        FROM ranked r
        JOIN top_counts t ON t.stat = r.stat
        WHERE r.r = 1 AND t.cnt = 1
        LIMIT ?`,
        [gameId.substring(0, 8), gameId, limit]
    )
    cache.set("game.getGameTraits." + gameId, rows, 1000 * 60 * 30)
    return rows as Trait[]
}