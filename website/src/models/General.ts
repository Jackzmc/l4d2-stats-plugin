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
        (SELECT 'revived_others' type,steamid,last_alias,times_revive_other value FROM stats_users
                WHERE times_revive_other > 0 ORDER BY stats_users.times_revive_other desc, stats_users.points desc limit 10)
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