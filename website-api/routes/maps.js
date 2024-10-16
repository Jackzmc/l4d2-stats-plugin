import Router from 'express'
const router = Router()
import routeCache from 'route-cache'

export default function(pool) {
    router.get('/', routeCache.cacheSeconds(120), async (req, res) => {
        const [rows] = await pool.query(`
            SELECT i.mapid as map_id, i.name as map_name, AVG(r.value) as avg_rating, COUNT(DISTINCT r.steamid) as num_ratings, COUNT(DISTINCT g.campaignID) as games_played, AVG(g.duration) as avg_duration, MAX(g.date_end) as last_played_time
            FROM map_info i
            LEFT JOIN left4dead2.map_ratings r ON i.mapid = r.map_id
            LEFT JOIN left4dead2.stats_games g ON g.map = i.mapid
            GROUP BY i.mapid
            ORDER BY games_played DESC, avg_rating DESC
        `)

        return res.json(rows.map(row => {
            return {
                map: {
                    id: row.map_id,
                    name: row.map_name
                },
                avgRating: row.avg_rating,
                numRatings: row.num_ratings,
                gamesPlayed: row.games_played,
                avgDuration: row.avg_duration,
                lastPlayedTime: row.last_played_time
            }
        }))
    })

    router.get('/:map', routeCache.cacheSeconds(120), async (req, res) => {
        const [maps] = await pool.query("SELECT name, chapter_count FROM map_info WHERE mapid = ?", [req.params.map])
        if(maps.length == 0) {
            return res.status(404).json({
                error: "NO_MAP_FOUND",
                message: "Unknown map"
            })
        }
        const map = maps[0]
        const [rows] = await pool.query(
            "SELECT r.*, u.last_alias as user_name FROM map_ratings r JOIN stats_users u ON u.steamid = r.steamid WHERE map_id = ?",
            [req.params.map]
        )
        let sum = 0

        const ratings = rows.map(row => {
            sum += row.value
            return {
                user: {
                    id: row.steamid,
                    name: row.user_name
                },
                value: row.value,
                comment: row.comment
            }
        })

        return res.json({
            map: {
                id: req.params.map,
                name: map.name,
                chapters: map.chapter_count
            },
            avgRating: sum / rows.length,
            ratings
        })
    })

    return router
}