import type { RowDataPacket } from 'mysql2';
import db from '../db/pool.ts'
import type { Difficulty, Survivor } from '../types/game.ts';

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

export async function getRecentGames(count = 8): Promise<RecentGame[]> {

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
        LIMIT ?
    `, [count])

    return recents.map((row,i) => {
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
        INNER JOIN map_info i ON i.mapid = g.map
        WHERE left(g.campaignID, 8) = ?
        LIMIT 1
    `, [id.substring(0, 8)])
    if(rows.length === 0) return null
    return {
        ...rows[0],
        server_tags: rows[0].server_tags.split(",")
    } as Game
}

export interface GameSession {
  id: number;
  steamid: string;
  last_alias: string;
  points: number;
  flags: number;
  join_time: number;
  characterType: Survivor;
  ping: number;
  ZombieKills: number;
  MeleeKills: number;
  SurvivorDamage: number;
  SurvivorFFCount: number;
  SurvivorFFTakenCount: number;
  SurvivorFFTakenDamage: number;
  Medkitsused: number;
  FirstAidShared: number;
  PillsUsed: number;
  MolotovsUsed: number;
  PipebombsUsed: number;
  BoomerBilesUsed: number;
  AdrenalinesUsed: number;
  DefibrillatorsUsed: number;
  DamageTaken: number;
  ReviveOtherCount: number;
  incaps: number;
  deaths: number;
  boomer_kills: number;
  smoker_kills: number;
  jockey_kills: number;
  hunter_kills: number;
  spitter_kills: number;
  SpecialInfectedKills: number;
  honks: number;
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

export async function getGameSessions(id: string): Promise<GameSession[]> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT g.id,
            g.steamid,
            last_alias,
            points,
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
            g.boomer_kills,
            g.smoker_kills,
            g.jockey_kills,
            g.hunter_kills,
            g.spitter_kills,
            g.smoker_kills,
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
        WHERE left(g.campaignID, 8) = '2ae2b0cc'
        ORDER BY SpecialInfectedKills desc, SurvivorDamage asc, ZombieKills desc, DamageTaken asc
    `, [id.substring(0,8)]
    )

    return rows as GameSession[]
}
