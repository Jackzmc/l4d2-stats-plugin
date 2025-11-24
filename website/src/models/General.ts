import db from '@/db/pool.ts'
import cache from '@/db/cache.ts'
import type { RowDataPacket } from 'mysql2';
import type { Player } from '@/db/types.ts';

export interface PlayerStatEntry extends Player {
    value: number
}
export interface PlayerTopStats {
    survivor_deaths: PlayerStatEntry[],
    survivor_ff: PlayerStatEntry[],
    heal_others: PlayerStatEntry[],
    revived_others: PlayerStatEntry[],
    survivor_incaps: PlayerStatEntry[],
    clowns_honked: PlayerStatEntry[],
}
export const TOP_STAT_NAMES: Record<keyof PlayerTopStats, string> = {
    survivor_deaths: 'Most Deaths',
    survivor_ff: 'Most Friendly Fire',
    heal_others: 'Healed the Most Players',
    revived_others: 'Revived the Most Players',
    survivor_incaps: 'Most Incaps',
    clowns_honked: 'Most Clown Honks',
}
export async function topStats(): Promise<PlayerTopStats> {
    const cacheObj = await cache.get("general.topStats")
    if(cacheObj) return cacheObj

    const [rows] = await db.execute<RowDataPacket[]>(`
        (SELECT 'survivor_deaths' type,steamid,last_alias name,deaths value FROM stats_users
        WHERE deaths > 0 ORDER BY stats_users.deaths desc, stats_users.points desc limit 10)
        union all
        (SELECT 'survivor_ff' type,steamid,last_alias,damage_dealt_friendly value FROM stats_users
                WHERE damage_dealt_friendly > 0 ORDER BY stats_users.damage_dealt_friendly desc, stats_users.points desc limit 10)
        union all
        (SELECT 'heal_others' type,steamid,last_alias,used_kit_other value FROM stats_users
                WHERE used_kit_other > 0 ORDER BY stats_users.used_kit_other desc, stats_users.points desc limit 10)
        union all
        (SELECT 'revived_others' type,steamid,last_alias,times_revived_other value FROM stats_users
                WHERE times_revived_other > 0 ORDER BY stats_users.times_revived_other desc, stats_users.points desc limit 10)
        union all 
        (SELECT 'survivor_incaps' type,steamid,last_alias,times_incapped value FROM stats_users
                WHERE times_incapped > 0 ORDER BY stats_users.times_incapped desc, stats_users.points desc limit 10 )
        union all
        (SELECT 'clowns_honked' type,steamid,last_alias,honks value FROM stats_users
            WHERE honks > 0 ORDER BY honks desc, stats_users.points desc limit 10 )
    `)

    const keys: Record<string, PlayerStatEntry[]> = {}
    for(const row of rows) {
        if(!keys[row.type]) keys[row.type] = []
        keys[row.type].push({
            steamid: row.steamid,
            name: row.name,
            value: Number(row.value)
        })
    } 
    cache.set("general.topStats", keys, 1000 * 60 * 60 * 6) // 6 hours
    return keys as Record<keyof PlayerTopStats, PlayerStatEntry[]>
}

export interface CommonStats {
    points: number,
    seconds_alive: number, // all time* calculated between checkpoints
    seconds_idle: number,
    seconds_dead: number,
    seconds_total: number, // computed
    kills_common: number,
    kills_melee: number,
    damage_taken: number,
    damage_taken_count: number,
    damage_taken_fall: number,
    damage_taken_friendly: number,
    damage_taken_friendly_count: number,
    damage_dealt: number,
    damage_dealt_friendly: number,
    damage_dealt_friendly_count: number,
    damage_dealt_fire: number,
    used_kit_self: number,
    used_kit_other: number,
    used_defib: number,
    used_molotov: number,
    used_pipebomb: number,
    used_bile: number,
    used_pills: number,
    used_adrenaline: number,
    times_revived_other: number,
    times_incapped: number,
    times_hanging: number,
    deaths: number,
    kills_boomer: number,
    kills_smoker: number,
    kills_jockey: number,
    kills_hunter: number,
    kills_spitter: number,
    kills_charger: number,
    kills_all_specials: number // computed,
    kills_tank: number,
    kills_witch: number,
    kills_fire: number,
    kills_pipebomb: number,
    kills_minigun: number,
    honks: number,
    witches_crowned: number,
    smokers_selfcleared: number,
    rocks_hitby: number,
    rocks_dodged: number,
    hunters_deadstopped: number,
    times_pinned: number,
    times_cleared_pinned: number,
    times_boomed_teammates: number,
    times_boomed: number,
    damage_dealt_tank: number,
    damage_dealt_witch: number,
    caralarms_activated: number,
    times_jumped: number,
    times_shove: number
}