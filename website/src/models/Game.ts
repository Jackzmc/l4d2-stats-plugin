import type { RowDataPacket } from 'mysql2';
import db from '../db/pool.ts'

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

export async function getRecentGames(): Promise<RecentGame[]> {

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
        LIMIT 12
    `)

    return recents.map((row,i) => {
        return {
            ...row,
            durationMins: Math.round(row.durationMins),
            tags: row.tags.split(",")
        } as RecentGame
    })
}