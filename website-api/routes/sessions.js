import Router from 'express'
const router = Router()
import routeCache from 'route-cache'

export default function(pool) {
    router.get('/', routeCache.cacheSeconds(120), async(req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 10;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;
            const [rows] = await pool.query("SELECT `stats_games`.*,last_alias,points FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid order by `stats_games`.id desc LIMIT ?,?", [offset, perPage])
            const [total] = await pool.execute("SELECT COUNT(*)  AS total_sessions FROM `stats_games`");
            return res.json({
                sessions: rows,
                total_sessions: total[0].total_sessions,
            })
        }catch(err) {
            console.error('/api/sessions',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/:session', routeCache.cacheSeconds(120), async(req,res) => {
        try {
            const sessId = parseInt(req.params.session);
            if(isNaN(sessId)) {
                res.status(422).json({error: "Session ID is not a valid number."})
            }else{
                const [row] = await pool.query("SELECT `stats_games`.*,last_alias,points FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid WHERE `stats_games`.`id`=?", [req.params.session])
                if(row.length > 0) {
                    let users = [];
                    if(row[0].campaignID) {
                        const [userlist] = await pool.query("SELECT stats_games.id,stats_users.steamid,stats_users.last_alias from `stats_games` inner join `stats_users` on `stats_users`.steamid = `stats_games`.steamid WHERE `campaignID`=?", [row[0].campaignID])
                        users = userlist;
                    }
                    res.json({session: row[0], users})
                } else 
                    res.json({sesssion: null, users: [], not_found: true})
            }
           
        }catch(err) {
            console.error('/api/sessions/:session',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    return router;
}