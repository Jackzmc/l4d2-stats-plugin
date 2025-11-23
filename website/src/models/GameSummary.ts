import db from '@/db/pool.ts'
import cache from '@/db/cache.ts'
import type { RowDataPacket } from 'mysql2';
import { getMapsWithPlayCount, type MapCountEntry } from './Map.ts';
import assert from 'assert';

export interface Summary {
    /** The total number of sessions (one per player per game) played */
    totalSessions: number,
    /** The total number of games played (a campaign was played start to finish) */
    totalGames: number
}
/**
 * Get the number of games played and the total number of sessions
 * @returns 
 */
export async function getTotals(): Promise<Summary> {
    const cacheObj = await cache.get("gameSummary.getTotals")
    if(cacheObj) return cacheObj

    const [totals] = await db.execute<RowDataPacket[]>(`SELECT
        (select count(*) from stats_games) total_games,
        (select count(*) from stats_sessions) total_sessions
    `);
    const summary = {
        totalSessions: totals[0].total_sessions,
        totalGames: totals[0].total_games
    }
    cache.set("gameSummary.getTotals", summary, 1000 * 60 * 10)
    return summary
}

/**
 * Get the most played and least played official maps
 * @returns [ least map, most map ]
 */
export async function getBestWorstOfficialMap(): Promise<[MapCountEntry, MapCountEntry]> {
    const cacheObj = await cache.get("gameSummary.getBestWorstOfficialMap")
    if(cacheObj) return cacheObj

    const sortedMaps = (await getMapsWithPlayCount(true))
        .sort((a, b) => a.count - b.count)

    assert(sortedMaps.length > 0)

    const topMap = sortedMaps.at(-1)!
    const btmMap = sortedMaps.at(0)!

    const output: [MapCountEntry, MapCountEntry] = [btmMap, topMap]
    cache.set("gameSummary.getBestWorstOfficialMap", output, 1000 * 60 * 10)
    return output
}

// TODO: types
export async function getSummaryTotals(): Promise<Record<string, number>>{
    const cacheObj = await cache.get("gameSummary.getSummaryTotals")
    if(cacheObj) return cacheObj

    const [totals] = await db.execute<RowDataPacket[]>(`SELECT 
            sum(g.duration_game) as game_duration,
            sum(nullif(kills_common,0)) as kills_common,
            sum(nullif(damage_dealt_friendly,0)) as survivor_ff,
            sum(used_kit_self) as used_kit_self,
            sum(used_kit_other) as used_kit_other,
            sum(used_defib) as used_defib,
            sum(used_pills) as used_pills,
            sum(used_adrenaline) as used_adrenaline,
            sum(used_molotov) as used_molotov,
            sum(used_pipebomb) as used_pipebomb,
            sum(used_bile) as used_bile,
            sum(damage_taken) as damage_taken,
            sum(kills_melee) as kills_melee,
            sum(times_revive_other) as times_revive_other,
            sum(deaths) as deaths,
            sum(times_incapped) as times_incapped,
            sum(nullif(kills_boomer,0)) as kills_boomer,
            sum(nullif(kills_jockey,0)) as kills_jockey,
            sum(nullif(kills_smoker,0)) as kills_smoker,
            sum(nullif(kills_spitter,0)) as kills_spitter,
            sum(nullif(kills_hunter,0)) as kills_hunter,
            sum(nullif(kills_charger,0)) as kills_charger,
            COUNT(*) AS total_sessions,
            COUNT(distinct game_id) AS total_games,
            (SELECT COUNT(*) FROM stats_users) AS total_users
        FROM stats_sessions s
        RIGHT JOIN stats_games g ON g.id = s.game_id
        WHERE g.date_start > 0
    `)
    cache.set("gameSummary.getSummaryTotals", totals[0], 1000 * 60 * 60) // 1 hour
    return totals[0]
}

// TODO: types
export async function getSummaryAverages(): Promise<Record<string, number>> {
    const cacheObj = await cache.get("gameSummary.getSummaryAverages")
    if(cacheObj) return cacheObj

    const [averages] = await db.execute<RowDataPacket[]>(`SELECT 
            avg(g.duration_game) as game_duration,
            avg(nullif(kills_common,0)) as kills_common,
            avg(nullif(damage_dealt_friendly,0)) as damage_dealt_friendly,
            avg(ping) as ping,
            avg(used_kit_self) as used_kit_self,
            avg(used_kit_other) as used_kit_other,
            avg(used_defib) as used_defib,
            avg(used_pills) as used_pills,
            avg(used_adrenaline) as used_adrenaline,
            avg(used_molotov) as used_molotov,
            avg(used_pipebomb) as used_pipebomb,
            avg(used_bile) as used_bile,
            avg(damage_taken) as damage_taken,
            avg(kills_melee) as kills_melee,
            avg(times_revive_other) as times_revive_other,
            avg(deaths) as deaths,
            avg(times_incapped) as times_incapped,
            avg(nullif(kills_boomer,0)) as kills_boomer,
            avg(nullif(kills_jockey,0)) as kills_jockey,
            avg(nullif(kills_smoker,0)) as kills_smoker,
            avg(nullif(kills_spitter,0)) as kills_spitter,
            avg(nullif(kills_hunter,0)) as kills_hunter,
            avg(nullif(kills_charger,0)) as kills_charger,
            (
                SELECT AVG(cnt)
                FROM (
                    SELECT COUNT(*) AS cnt
                    FROM stats_sessions
                    GROUP BY game_id
                ) x
            ) AS avg_players
        FROM stats_games g
        RIGHT JOIN stats_sessions s ON g.id = s.game_id
        WHERE g.date_start > 0
    `)

    const avgs = averages[0] as Record<string, number>
    Object.keys(avgs).forEach(key => avgs[key] = Number(avgs[key]))
    const output = {
        ...avgs,
        difficulty: Math.round(averages[0].difficulty)
    }
    cache.set("gameSummary.getSummaryAverages", output, 1000 * 60 * 60) // 1 hour
    return output
}