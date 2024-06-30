import Router from 'express'
const router = Router()
import routeCache from 'route-cache'

export default function(pool) {
    router.get('/', routeCache.cacheSeconds(120), async (req, res) => {
        const [rows] = await pool.query(`
            SELECT i.mapid as map_id, i.name as map_name, AVG(r.value) as avg_rating, COUNT(g.id) as games_played
            FROM map_info i
            LEFT JOIN left4dead2.map_ratings r ON i.mapid = r.map_id
            LEFT JOIN left4dead2.stats_games g ON g.map = i.mapid
            GROUP BY i.mapid
            ORDER BY avg_rating DESC, games_played DESC
        `)

        return res.json(rows)
    })

    router.get('/:map', routeCache.cacheSeconds(120), async (req, res) => {
        const [rows] = await pool.query(
            "SELECT i.name, r.*, u.last_alias as user_name FROM map_ratings r LEFT JOIN map_info i ON i.mapid = r.map_id JOIN stats_users u ON u.steamid = r.steamid WHERE map_id = ?",
            [req.params.map]
        )

        return res.json(rows.map(row => {
            return {
                user: {
                    id: row.steamid,
                    name: row.user_name
                },
                rating: row.value,
                map: {
                    id: row.map_id,
                    name: row.name
                }
            }
        }))
    })

    return router
}