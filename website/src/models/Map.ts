import type { RowDataPacket } from 'mysql2';
import db from '@/db/pool.ts'

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

export type MapDetailInfo = MapRatingEntry & { chapter_count: number, flags: number }
/**
 * Gets a map's ratings
 * @param map id of map
 */
export async function getMapInfo(
    map: string
): Promise<MapDetailInfo | null> {

    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT i.mapid map, i.name name, i.chapter_count, i.flags, AVG(value) avgRating, COUNT(r.map_id) ratings, count gamesPlayed, duration avgMinutesPlayed
        FROM stats_map_info i
        LEFT JOIN stats_map_ratings r ON r.map_id = i.mapid
        LEFT JOIN (SELECT map, COUNT(campaignID) count, AVG(duration) duration FROM stats_games GROUP BY map) as g
            ON g.map = i.mapid
        WHERE mapid = ?
    `, [ map ])
    const row = rows[0]
    if(!row || !row.map) return null
    return {
        map: row.map,
        name: row.name,
        chapter_count: row.chapter_count,
        flags: row.flags,
        avgRating: Number(row.avgRating),
        ratings: Number(row.ratings),
        gamesPlayed: Number(row.gamesPlayed),
        avgMinutesPlayed: Number(row.avgMinutesPlayed)
    } as MapDetailInfo
}


export async function getMaps(mapId: string): Promise<MapInfo[]> {
    const [rows] = await db.execute<RowDataPacket[]>("SELECT name, chapter_count, flags FROM stats_map_info WHERE mapid = ?", [ mapId ])
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
export async function getMapsWithPlayCount(officialMapsOnly: boolean = false, limit: number | null = null): Promise<MapCountEntry[]> {
    const officialMapCondition = officialMapsOnly ? `AND stats_map_info.flags & ${MapFlags.OfficialMap}` : ''
    const limitClause = limit != null ? "LIMIT ?" : ""
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT map, stats_map_info.name, COUNT(map) count 
        FROM stats_games 
        LEFT JOIN stats_map_info ON stats_map_info.mapid = stats_games.map ${officialMapCondition}
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
export async function getMapsWithRatings(
    sortBy: string = "avgRating", 
    sortAscending: boolean = false
): Promise<MapRatingEntry[]> {
    sortBy = db.escapeId(sortBy)

    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT map_id as map, stats_map_info.name as name, AVG(value) avgRating, COUNT(value) ratings, count gamesPlayed, duration avgMinutesPlayed
        FROM stats_map_ratings
        JOIN stats_map_info ON stats_map_info.mapid = map_id
        JOIN (SELECT map, COUNT(campaignID) count, AVG(duration) duration FROM stats_games GROUP BY map) as games
        ON games.map = mapid
        GROUP BY map_id
        ORDER BY ${sortBy} ${sortAscending ? "ASC" : "DESC"}
    `)
    
    return rows.map(row => {
        return {
            map: row.map,
            name: row.name,
            avgRating: Number(row.avgRating),
            ratings: Number(row.ratings),
            gamesPlayed: Number(row.gamesPlayed),
            avgMinutesPlayed: Number(row.avgMinutesPlayed)
        }
    })
}

export interface MapRating {
    rating: number,
    comment?: string,
    rater: string

}
export async function getRatings(map: string): Promise<MapRating[]> {
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT value rating, comment, steamid rater
        FROM stats_map_ratings r
        WHERE r.map_id = ?
    `, [map])

    return rows.map(row => {
        return {
            rating: Number(row.rating),
            comment: row.comment,
            rater: row.rater
        } as MapRating
    })
}