import Router from 'express'
const router = Router()
import routeCache from 'route-cache'

export default function(pool) {
    router.get('/', routeCache.cacheSeconds(120), async (req, res) => {
        const [rows] = await pool.query(
            "SELECT i.name as map_name, r.map_id, AVG(value) as avg_rating FROM map_ratings r LEFT JOIN map_info i ON i.mapid = r.map_id GROUP BY map_id ORDER BY avg_rating DESC"
        )

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