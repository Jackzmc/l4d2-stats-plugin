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
        SELECT
            i.mapid map,
            i.name name,
            i.chapter_count,
            i.flags,
            AVG(r.value) avgRating,
            COUNT(r.map_id) ratings,
            (SELECT AVG(g.duration_game) / 60 avgMinutesPlayed FROM stats_games g WHERE map_id = i.mapid) avgMinutesPlayed,
            (SELECT COUNT(*) FROM stats_games g WHERE g.map_id = i.mapid ) gamesPlayed
        FROM stats_map_info i
        LEFT JOIN stats_map_ratings r ON r.map_id = i.mapid
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
    const [rows] = await db.execute<RowDataPacket[]>(
        "SELECT name, chapter_count, flags FROM stats_map_info WHERE mapid = ?", 
        [ mapId ]
    )
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
    map_id: string,
    name?: string,
    count: number
}
/**
 * Gets the total number of games played per map
 * @param [officialMapsOnly=false] Only return official maps
 * @returns object, key being map id, value being count
 */
export async function getMapsWithPlayCount(officialMapsOnly: boolean = false, limit: number | null = null): Promise<MapCountEntry[]> {
    const officialMapCondition = officialMapsOnly ? `WHERE i.flags & ${MapFlags.OfficialMap}` : ''
    const limitClause = limit != null ? "LIMIT ?" : ""
    const [rows] = await db.execute<RowDataPacket[]>(`
        SELECT g.map_id, i.name, COUNT(g.map_id) count
        FROM stats_games g
        LEFT JOIN stats_map_info i ON i.mapid = g.map_id
        ${officialMapCondition}
        GROUP BY g.map_id
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
        SELECT
            i.mapid map,
            i.name name,
            i.chapter_count,
            i.flags,
            AVG(r.value) avgRating,
            COUNT(r.map_id) ratings,
            (SELECT AVG(g.duration_game) avgMinutesPlayed FROM stats_games g WHERE map_id = i.mapid) avgMinutesPlayed,
            (SELECT COUNT(*) FROM stats_sessions s JOIN stats_games g ON g.id = s.game_id WHERE g.map_id = i.mapid ) gamesPlayed
        FROM stats_map_info i
        LEFT JOIN stats_map_ratings r ON r.map_id = i.mapid
        GROUP BY mapid
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