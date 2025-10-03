import type { RowDataPacket } from 'mysql2';
import db from '../db/pool.ts'

export interface MapInfo {
    id: string,
    name: string,
    numChapters: boolean,
    isOfficialMap: boolean
}

export const enum MapFlags {
    None,
    OfficialMap = 1
}

const OFFICIAL_MAP_REGEX = new RegExp(/c(\d+)m(\d+)\_/)

export async function getMapInfo(mapId: string): Promise<MapInfo | null> {
    const [rows] = await db.query<RowDataPacket[]>("SELECT name, chapter_count, flags FROM map_info WHERE mapid = ?", [ mapId ])
    if(rows.length === 0) return null

    return {
        id: mapId,
        name: rows[0].name,
        numChapters: rows[0].chapter_count,
        isOfficialMap: (rows[0].flags & MapFlags.OfficialMap) == MapFlags.OfficialMap
    }
}

export async function getMaps(mapId: string): Promise<MapInfo[]> {
    const [rows] = await db.query<RowDataPacket[]>("SELECT name, chapter_count, flags FROM map_info WHERE mapid = ?", [ mapId ])
    return rows.map(row => {
        return {
            id: mapId,
            name: row.name,
            numChapters: row.chapter_count,
            isOfficialMap: (row.flags & MapFlags.OfficialMap) == MapFlags.OfficialMap
        }
    })
}


export interface MapCountEntry {
    map: string,
    name?: string,
    count: number
}
/**
 * Gets the total number of games played per map
 * @param [officialMapsOnly=false] Only return official maps
 * @returns object, key being map id, value being count
 */
export async function getMapPlayCount(officialMapsOnly: boolean = false, limit: number | null = null): Promise<MapCountEntry[]> {
    const officialMapCondition = officialMapsOnly ? `AND map_info.flags & ${MapFlags.OfficialMap}` : ''
    const limitClause = limit != null ? "LIMIT ?" : ""
    const [rows] = await db.query<RowDataPacket[]>(`
        SELECT map, map_info.name, COUNT(map) count 
        FROM stats_games 
        RIGHT JOIN map_info ON map_info.mapid = stats_games.map ${officialMapCondition}
        WHERE map IS NOT NULL
        GROUP BY map
        ORDER BY count DESC
        ${limitClause}
    `, [ limit ])
    return rows as MapCountEntry[]
}

export interface MapRatingEntry {
    map: string,
    name: string,
    avgRating: number,
    ratings: number,
    gamesPlayed: number,
    avgMinutesPlayed: number
}

/**
 * Gets all maps and their ratings
 * @param [officialMapsOnly=false] Only return official maps
 * @returns object, key being map id, value being count
 */
export async function getMapRatings(): Promise<MapRatingEntry[]> {
    const [rows] = await db.query<RowDataPacket[]>(`
        SELECT map_id map, map_info.name name, AVG(value) avgRating, COUNT(value) ratings, count gamesPlayed, duration avgDuration
        FROM map_ratings
        JOIN map_info ON map_info.mapid = map_id
        JOIN (SELECT map, COUNT(campaignID) count, AVG(duration) duration FROM stats_games GROUP BY map) as games
        WHERE games.map = map_id
        GROUP BY map_id
        ORDER BY avgRating DESC
    `)
    return rows.map(row => {
        return {
            map: row.map,
            name: row.name,
            avgRating: Number(row.avgRating),
            ratings: Number(row.ratings),
            gamesPlayed: Number(row.gamesPlayed),
            avgMinutesPlayed: Number(row.avgDuration)
        }
    })
}
