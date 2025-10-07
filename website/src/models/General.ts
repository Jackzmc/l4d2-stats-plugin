import type { RowDataPacket } from 'mysql2';
import db from '@/db/pool.ts'
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
    times_mvp: PlayerStatEntry[]
}
export const TOP_STAT_NAMES: Record<keyof PlayerTopStats, string> = {
    survivor_deaths: 'Most Deaths',
    survivor_ff: 'Most Friendly Fire',
    heal_others: 'Healed the Most Players',
    revived_others: 'Revived the Most Players',
    survivor_incaps: 'Most Incaps',
    clowns_honked: 'Most Clown Honks',
    times_mvp: 'Most Times MVP'
}
export async function topStats(): Promise<PlayerTopStats> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        (SELECT 'survivor_deaths' type,steamid,last_alias name,survivor_deaths value FROM stats_users
        WHERE survivor_deaths > 0 ORDER BY stats_users.survivor_deaths desc, stats_users.points desc limit 10)
        union all
        (SELECT 'survivor_ff' type,steamid,last_alias,survivor_ff value FROM stats_users
                WHERE survivor_ff > 0 ORDER BY stats_users.survivor_ff desc, stats_users.points desc limit 10)
        union all
        (SELECT 'heal_others' type,steamid,last_alias,heal_others value FROM stats_users
                WHERE heal_others > 0 ORDER BY stats_users.heal_others desc, stats_users.points desc limit 10)
        union all
        (SELECT 'revived_others' type,steamid,last_alias,revived_others value FROM stats_users
                WHERE revived_others > 0 ORDER BY stats_users.revived_others desc, stats_users.points desc limit 10)
        union all 
        (SELECT 'survivor_incaps' type,steamid,last_alias,survivor_incaps value FROM stats_users
                WHERE survivor_incaps > 0 ORDER BY stats_users.survivor_incaps desc, stats_users.points desc limit 10 )
        union all
        (SELECT 'clowns_honked' type,steamid,last_alias,clowns_honked value FROM stats_users
            WHERE clowns_honked > 0 ORDER BY stats_users.clowns_honked desc, stats_users.points desc limit 10 )
        union all
        (SELECT 'times_mvp', g.steamid,su.last_alias as name, SUM(honks) value
                FROM stats_games g
                INNER JOIN stats_users as su
                    ON su.steamid = g.steamid
                WHERE g.honks > 0
                GROUP BY g.steamid
                ORDER by value DESC
                LIMIT 10)
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
    return keys as Record<keyof PlayerTopStats, PlayerStatEntry[]>
}