import type { RowDataPacket } from 'mysql2';
import db from '@/db/pool.ts'
import { QueryConditionBuilder } from '@/db/helpers.ts';
import type { Difficulty, Survivor } from '@/types/game.ts';
import type { Player } from '@/db/types.ts';

export interface RecentGame {
  numPlayers: number;
  campaignId: string;
  map: string;
  dateEnd: number;
  durationMins: number;
  difficulty: number;
  gamemode: string;
  commonsKilled: string;
  friendlyDamage: string;
  deaths: string;
  medkitsUsed: string;
  throwablesUsed: string;
  tags: string[];
  name: string;
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
        SELECT COUNT(g.campaignID) as numPlayers,
            g.campaignID campaignId,
            g.map map,
            g.date_end dateEnd,
            (g.date_end - g.date_start) / 60 durationMins,
            difficulty,
            gamemode,
            SUM(ZombieKills) as commonsKilled,
            SUM(SurvivorDamage) as friendlyDamage,
            SUM(Deaths) as deaths,
            SUM(MedkitsUsed) medkitsUsed,
            (SUM(MolotovsUsed) + SUM(PipebombsUsed) + SUM(BoomerBilesUsed)) as throwablesUsed,
            server_tags tags,
            i.name as name
        FROM stats_games as g
        INNER JOIN map_info i ON i.mapid = g.map
        GROUP BY g.campaignID
        ORDER BY dateEnd DESC
        LIMIT ?, ?
    `, [offset, limit])

    return recents.map((row,i) => {
        return {
            ...row,
            durationMins: Math.round(row.durationMins),
            tags: row.tags.split(",")
        } as RecentGame
    })
}


interface FilterOptions { gamemode?: string|null, difficulty?: number|null, map_type?: number|null, tag?: string|null, map?: string|null }
/**
 * Returns count amount of recently played games
 * @param limit number of games to return
 * @returns Game with some sums and game info
 */
export async function getFilteredGames(opts: FilterOptions = {}, page = 0, limit = 8): Promise<RecentGame[]> {
    const offset = (page - 1) * limit

    // const [total] = await db.execute("SELECT COUNT(DISTINCT campaignID) as total FROM `stats_games`")
    const builder = new QueryConditionBuilder()
    if(opts.gamemode) builder.push("gamemode = ?", opts.gamemode)
    if(opts.difficulty != undefined) builder.push("difficulty = ?", opts.difficulty)
    if(opts.map_type) builder.push("i.flags = ?", opts.map_type)
    if(opts.tag) builder.push("FIND_IN_SET(?, server_tags)", opts.tag)
    if(opts.map) builder.push("map LIKE ?", `${opts.map}%`)

    const [whereClause, data] = builder.buildFullWhere()

    const [games] = await db.execute<RowDataPacket[]>(`
        SELECT COUNT(g.campaignID) as numPlayers,
            g.campaignID campaignId,
            g.map map,
            g.date_end dateEnd,
            (g.date_end - g.date_start) / 60 durationMins,
            difficulty,
            gamemode,
            SUM(ZombieKills) as commonsKilled,
            SUM(SurvivorDamage) as friendlyDamage,
            SUM(Deaths) as deaths,
            SUM(MedkitsUsed) medkitsUsed,
            (SUM(MolotovsUsed) + SUM(PipebombsUsed) + SUM(BoomerBilesUsed)) as throwablesUsed,
            server_tags tags,
            i.name as name
        FROM stats_games as g
        INNER JOIN map_info i ON i.mapid = g.map
        ${whereClause}
        GROUP BY g.campaignID
        ORDER BY dateEnd DESC
        LIMIT ?, ?
    `, [...data, offset, limit])

    console.debug(whereClause, [...data, offset, limit])

    return games.map((row,i) => {
        return {
            ...row,
            durationMins: Math.round(row.durationMins),
            tags: row.tags.split(",")
        } as RecentGame
    })
}

export interface Game {
    map: string;
    map_name: string,
    difficulty: Difficulty,
    gamemode: string,
    date: number;
    duration: number;
    server_tags: string[];
    finale_time: number;
    campaignID: string;
    specials_killed: number;
    commons_killed: number;
    honks: number;
    medkits_used: number;
    pills_used: number,
    adrenalines_used: number,
    biles_used: number;
    pipes_used: number;
    molotovs_used: number;
    incaps: number;
    deaths: number;
    damage_taken: number;
}

/**
 * Returns game data, with sums of some its sessions' stats
 * @param id gamei d
 * @returns 
 */
export async function getGame(id: string): Promise<Game | null> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT i.mapid map, i.name as map_name, g.difficulty difficulty, g.gamemode gamemode, g.date_end date, g.duration, g.server_tags, g.finale_time, g.campaignID,
            SUM(g.SpecialInfectedKills) specials_killed,
            SUM(ZombieKills) commons_killed,
            SUM(g.honks) honks,
            SUM(medkitsUsed) medkits_used,
            SUM(PillsUsed) pills_used,
            SUM(AdrenalinesUsed) adrenalines_used,
            SUM(BoomerBilesUsed) biles_used,
            SUM(PipebombsUsed) pipes_used,
            SUM(MolotovsUsed) molotovs_used,
            SUM(Incaps) incaps,
            SUM(Deaths) deaths,
            SUM(DamageTaken) damage_taken
        FROM stats_games g
        JOIN map_info i ON i.mapid = g.map
        WHERE left(g.campaignID, 8) = ?
        LIMIT 1
    `, [id.substring(0, 8)])
    // row[0] will exist due to use of AVG(), check for null map:
    if(rows.length === 0 || !rows[0].map) return null
    return {
        ...rows[0],
        duration: Math.round(rows[0].duration),
        server_tags: rows[0].server_tags.split(",")
    } as Game
}

export interface GameSessionPartial extends Player {
  id: number;
  points: number;
  flags: number;
  characterType: Survivor;
  ZombieKills: number;
  MeleeKills: number;
  SurvivorDamage: number;
  Medkitsused: number;
  PillsUsed: number;
  MolotovsUsed: number;
  PipebombsUsed: number;
  BoomerBilesUsed: number;
  AdrenalinesUsed: number;
  DamageTaken: number;
  incaps: number;
  deaths: number;
  SpecialInfectedKills: number;
  honks: number;
}

/**
 * Returns list of sessions for a game, with partial data of each session
 * @param id game id
 * @returns 
 */
export async function getSessions(id: string): Promise<GameSessionPartial[]> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT g.id,
            g.steamid,
            last_alias name,
            points,
            g.flags,
            g.characterType,
            g.ZombieKills,
            g.SurvivorDamage,
            g.Medkitsused,
            g.PillsUsed,
            g.MolotovsUsed,
            g.PipebombsUsed,
            g.BoomerBilesUsed,
            g.AdrenalinesUsed,
            g.DamageTaken,
            g.incaps,
            g.deaths,
            g.SpecialInfectedKills,
            g.honks
        FROM stats_games g
        INNER JOIN stats_users ON g.steamid = stats_users.steamid
        WHERE left(g.campaignID, 8) = ?
        ORDER BY SpecialInfectedKills desc, SurvivorDamage asc, ZombieKills desc, DamageTaken asc
    `, [id.substring(0,8)]
    )

    return rows as GameSessionPartial[]
}

export interface GameSession extends GameSessionPartial {
    map: string,
    map_name: string,
    gamemode: string,
    difficulty: Difficulty,
    server_tags: string[],
    join_time: number;
    ping: number;
    duration: number,
    date_start: number,
    date_end: number,
    MeleeKills: number;
    SurvivorFFCount: number;
    SurvivorFFTakenCount: number;
    SurvivorFFTakenDamage: number;
    FirstAidShared: number;
    DefibrillatorsUsed: number;
    DamageTaken: number;
    ReviveOtherCount: number;
    boomer_kills: number;
    smoker_kills: number;
    charger_kills: number;
    jockey_kills: number;
    hunter_kills: number;
    spitter_kills: number;
    top_weapon: string;
    minutes_idle: number;
    WitchesCrowned: number;
    SmokersSelfCleared: number;
    RocksHitBy: number;
    RocksDodged: number;
    HuntersDeadstopped: number;
    TimesPinned: number;
    ClearedPinned: number;
    BoomedTeammates: number;
    TimesBoomed: number;
    DamageToTank: number;
    DamageToWitch: number;
    DamageDealt: number;
    CarAlarmsActivated: number;
}

/**
 * Returns full session info, including user, tags, gamemode, etc
 */
export async function getSession(id: number | string): Promise<GameSession | null> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT g.id,
            g.steamid,
            last_alias name,
            points,
            g.server_tags,
            g.map,
            i.name as map_name,
            g.gamemode,
            g.difficulty,
            (g.date_end - g.date_start) / 60 as duration,
            g.date_start,
            g.date_end,
            g.flags,
            g.join_time,
            g.characterType,
            g.ping,
            g.ZombieKills,
            g.MeleeKills,
            g.SurvivorDamage,
            g.SurvivorFFCount,
            g.SurvivorFFTakenCount,
            g.SurvivorFFTakenDamage,
            g.Medkitsused,
            g.FirstAidShared,
            g.PillsUsed,
            g.MolotovsUsed,
            g.PipebombsUsed,
            g.BoomerBilesUsed,
            g.AdrenalinesUsed,
            g.DefibrillatorsUsed,
            g.DamageTaken,
            g.ReviveOtherCount,
            g.incaps,
            g.deaths,
            g.smoker_kills,
            g.boomer_kills,
            g.jockey_kills,
            g.hunter_kills,
            g.spitter_kills,
            g.charger_kills,
            g.SpecialInfectedKills,
            g.honks,
            g.top_weapon,
            g.minutes_idle,
            g.WitchesCrowned,
            g.SmokersSelfCleared,
            g.RocksHitBy,
            g.RocksDodged,
            g.HuntersDeadstopped,
            g.TimesPinned,
            g.ClearedPinned,
            g.BoomedTeammates,
            g.TimesBoomed,
            g.DamageToTank,
            g.DamageToWitch,
            g.DamageDealt,
            g.CarAlarmsActivated
        FROM stats_games g
        INNER JOIN stats_users ON g.steamid = stats_users.steamid
        INNER JOIN map_info i ON g.map = i.mapid
        WHERE g.id = ?
        LIMIT 1
    `, [id]
    )
    if(rows.length === 0) return null
    return {
        ...rows[0],
        server_tags: rows[0].server_tags.split(","),
        duration: Math.round(rows[0].duration),
    } as GameSession
}

/**
 * Returns all players in a given game
 * @param id game id
 * @returns object[] -> { sessionId, steamid, playerName }[]
 */
export async function getSessionPlayers(id: string): Promise<(Player & { sessionId: number })[]> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT id sessionId, g.steamid, u.last_alias playerName
        FROM stats_games g
        INNER JOIN stats_users u ON u.steamid = g.steamid
        WHERE left(campaignID, 8) = ?
    `, [id.substring(0,8)])

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
    const [rows] = await db.execute<RowDataPacket[]>(
    "SELECT distinct gamemode FROM stats_games"
    )
    return rows.map(row => row.gamemode)
}
/**
 * Returns list of all distinct server tags 
 * @returns string[]
 */
export async function getServerTags(): Promise<string[]> {
    const [rows] = await db.execute<RowDataPacket[]>(
    "SELECT distinct server_tags FROM stats_games WHERE server_tags != ''"
    )
    // rows returns unique combinations of tags, 
    // but we need to split by comma to get full list

    // count the number of occurrences of every tag
    const obj: Record<string, number> = {}
    const flatTags = rows.map(row => row.server_tags.split(",")).flat()
    flatTags.forEach(tag => {
        if(!obj[tag]) obj[tag] = 0
        obj[tag]++
    })

    // return sorted list of all tags, in descending order by count
    return Object.entries(obj)
        .sort(([,val1],[,val2]) => val2 - val1)
        .map(([key]) => key)
}