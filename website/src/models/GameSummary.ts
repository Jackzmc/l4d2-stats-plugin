import type { RowDataPacket } from 'mysql2';
import db from '@/db/pool.ts'
import { getMapPlayCount, type MapCountEntry } from './Map.ts';
import assert from 'assert';

export interface Summary {
    /** The total number of sessions (one per player per game) played */
    totalSessions: number,
    /** The total number of games played (a campaign was played start to finish) */
    totalGames: number
}
export async function getTotals(): Promise<Summary> {
    const [totals] = await db.execute<RowDataPacket[]>(`SELECT
        (select count(distinct campaignID) from stats_games) AS total_games, 
        (SELECT COUNT(*) FROM stats_games) AS total_sessions
    `);
    return {
        totalSessions: totals[0].total_sessions,
        totalGames: totals[0].total_games
    }
}

/**
 * Get the most played and least played official maps
 * @returns [ least map name, highest map name ]
 */
export async function getBestWorstOfficialMap(): Promise<[MapCountEntry, MapCountEntry]> {
    const sortedMaps = (await getMapPlayCount(true))
        .sort((a, b) => a.count - b.count)

    assert(sortedMaps.length > 0)

    const topMap = sortedMaps.at(-1)!
    const btmMap = sortedMaps.at(0)!

    return [btmMap, topMap]
}

// TODO: types
export async function getSummaryTotals(): Promise<Record<string, number>>{
    const [totals] = await db.execute<RowDataPacket[]>(`SELECT 
        sum(nullif(finale_time,0)) as finale_time, 
        sum(date_end - date_start) as game_duration,
        sum(nullif(ZombieKills,0)) as zombie_kills, 
        sum(nullif(SurvivorDamage,0)) as survivor_ff, 
        sum(MedkitsUsed) as MedkitsUsed, 
        sum(FirstAidShared) as FirstAidShared,
        sum(PillsUsed) as PillsUsed, 
        sum(AdrenalinesUsed) as AdrenalinesUsed,
        sum(MolotovsUsed) as MolotovsUsed, 
        sum(PipebombsUsed) as PipebombsUsed, 
        sum(BoomerBilesUsed) as BoomerBilesUsed, 
        sum(DamageTaken) as DamageTaken, 
        sum(MeleeKills) as MeleeKills, 
        sum(ReviveOtherCount) as ReviveOtherCount, 
        sum(DefibrillatorsUsed) as DefibrillatorsUsed,
        sum(Deaths) as Deaths, 
        sum(Incaps) as Incaps, 
        sum(nullif(boomer_kills,0)) as boomer_kills, 
        sum(nullif(jockey_kills,0)) as jockey_kills, 
        sum(nullif(smoker_kills,0)) as smoker_kills, 
        sum(nullif(spitter_kills,0)) as spitter_kills, 
        sum(nullif(hunter_kills,0)) as hunter_kills,
        sum(nullif(charger_kills,0)) as charger_kills,
        (SELECT COUNT(*) FROM \`stats_games\`) AS total_sessions,
        (SELECT COUNT(distinct(campaignID)) from stats_games) AS total_games,
        (SELECT COUNT(*) FROM \`stats_users\`) AS total_users
        FROM stats_games WHERE date_start > 0`
    )
    return totals[0]
}

// TODO: types
export async function getSummaryAverages(): Promise<Record<string, number>> {
    const [averages] = await db.execute<RowDataPacket[]>(`SELECT 
        avg(nullif(finale_time,0)) as finale_time, 
        avg(date_end - date_start) as game_duration,
        avg(nullif(ZombieKills,0)) as zombie_kills, 
        avg(nullif(SurvivorDamage,0)) as survivor_ff, 
        avg(MedkitsUsed) as MedkitsUsed, 
        avg(FirstAidShared) as FirstAidShared,
        avg(PillsUsed) as PillsUsed, 
        avg(AdrenalinesUsed) as AdrenalinesUsed,
        avg(MolotovsUsed) as MolotovsUsed, 
        avg(PipebombsUsed) as PipebombsUsed, 
        avg(BoomerBilesUsed) as BoomerBilesUsed, 
        avg(DamageTaken) as DamageTaken, 
        avg(difficulty) as difficulty, 
        avg(MeleeKills) as MeleeKills, 
        avg(ping) as ping, 
        avg(ReviveOtherCount) as ReviveOtherCount, 
        avg(DefibrillatorsUsed) as DefibrillatorsUsed,
        avg(Deaths) as Deaths, 
        avg(Incaps) as Incaps, 
        avg(nullif(boomer_kills,0)) as boomer_kills, 
        avg(nullif(jockey_kills,0)) as jockey_kills, 
        avg(nullif(smoker_kills,0)) as smoker_kills, 
        avg(nullif(spitter_kills,0)) as spitter_kills, 
        avg(nullif(hunter_kills,0)) as hunter_kills,
        avg(nullif(charger_kills,0)) as charger_kills,
        (SELECT avg(games.players) 
            FROM (SELECT COUNT(campaignID) as players FROM stats_games GROUP BY campaignID) as games) as avgPlayers
        FROM stats_games WHERE date_start > 0`
    )

    const avgs = averages[0] as Record<string, number>
    Object.keys(avgs).forEach(key => avgs[key] = Number(avgs[key]))
    return {
        ...avgs,
        difficulty: Math.round(averages[0].difficulty)
    }
}