const router = require('express').Router();
const routeCache = require('route-cache');

module.exports = (pool) => {
    router.get('/random', routeCache.cacheSeconds(86400), async(req,res) => {
        try {
            const [results] = await pool.execute("SELECT * FROM `left4dead2`.`stats_users` ORDER BY RAND() LIMIT 1")
            return res.json({user: results[0]})
        }catch(err) {
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    router.get('/:user', async(req,res) => {
        const user = req.params.user.replace(/\+-/,' ')

        try {
            const [rows] = await pool.query("SELECT * FROM `stats_users` WHERE STRCMP(`last_alias`,?) = 0 OR `steamid` = ?", [user, req.params.user])
            if(rows.length > 0) {
                res.json({
                    user:rows[0],
                })
            }else{
                res.json({ 
                    user: null, 
                    not_found: true 
                })
            }
        }catch(err) {
            console.error('[/api/user/:user]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    router.get('/:user/totals/:gamemode',async(req,res) => {
        try {
            const [rows] = await pool.query("SELECT `map`, `difficulty` FROM `stats_games` WHERE `steamid` = ? AND `gamemode` = ?", [req.params.user, req.params.gamemode])
            if(rows.length > 0) {
                let maps = {};
                let difficulty = {
                    easy: 0,
                    normal: 0,
                    advanced: 0,
                    expert: 0
                }
                rows.forEach(row => {
                    if(!maps[row.map]) maps[row.map] = {
                        difficulty: {
                            easy: 0,
                            normal: 0,
                            advanced: 0,
                            expert: 0
                        },
                        wins: 0
                    }
                    maps[row.map].wins++;
                    const diff = DIFFICULTIES[row.difficulty];
                    maps[row.map].difficulty[diff]++;
                    difficulty[diff]++;
                })
                const mapTotals = [];
                for(const map in maps) {
                    mapTotals.push({
                        map,
                        ...maps[map]
                    })
                }
                res.json({
                    totals: {
                        wins: rows.length,
                        difficulty
                    }, 
                    maps: mapTotals,
                })
            }else{
                res.json({maps: [], totals: { wins: 0, gamemodes: [], difficulty: []}})
            }
        }catch(err) {
            console.error('/api/user/:user/totals/:gamemode',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/:user/flags/:flag', async(req,res) => {
        try {
            const flag = parseInt(req.params.flag)
            if(isNaN(flag) || flag <= 0) {
                return res.status(400).json({error: 'Bad Request', reason: 'INVALID_FLAG_TYPE'})
            }
            const [rows] = await pool.query("SELECT COUNT(*) as value FROM stats_games where steamid = ? AND flags & ? = ?", [req.params.user, flag, flag])
            const value = rows.length > 0 ? rows[0].value : 0;
            res.json({value})
        }catch(err) {
            console.error('/api/user/:user/flags/:flag',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    //TODO: points system
    router.get('/:user/top', routeCache.cacheSeconds(60), async(req,res) => {
        try {
            const [top_map] = await pool.execute("SELECT map as k, COUNT(*) as count FROM `stats_games` WHERE steamid = ? GROUP BY `map` ORDER BY count desc", [req.params.user])
            const [top_character] = await pool.execute("SELECT characterType as k, COUNT(*) as count FROM `stats_games` WHERE steamid = ? AND characterType IS NOT NULL GROUP BY `characterType` ORDER BY count DESC LIMIT 1", [req.params.user]) 
            const [top_weapon] = await pool.execute("SELECT top_weapon as k, COUNT(*) as count FROM `stats_games` WHERE steamid = ? AND top_weapon IS NOT NULL AND top_weapon != '' GROUP BY `top_weapon` ORDER BY count DESC LIMIT 1 ", [req.params.user])
            const [top_session] = await pool.execute("SELECT *, map, date_end - date_start as difference FROM stats_games WHERE date_end > 0 AND date_start > 0 AND steamid = ? ORDER BY difference ASC LIMIT 1", [req.params.user])
            const [map_ratio] = await pool.execute('SELECT (SELECT COUNT(*) FROM `stats_games` WHERE `steamid` = ? AND `map` NOT RLIKE "^c[0-9]+m") as custom,  (SELECT COUNT(*) FROM `stats_games` WHERE `steamid` = ? AND `map` RLIKE "^c[0-9]+m") as official FROM `stats_games` LIMIT 1', [req.params.user, req.params.user])
            const totalMapsCount = map_ratio[0].custom + map_ratio[0].official
            res.json({
                topMap: top_map.length > 0 ? top_map[0] : null, //SELECT map, COUNT(*) as c FROM `stats_games` WHERE steamid = 'STEAM_1:0:49243767' GROUP BY `map` ORDER BY c desc
                topCharacter: top_character.length > 0 ? top_character[0] : null,
                topWeapon: top_weapon.length > 0 ? top_weapon[0].k : null,
                bestSessionByTime: top_session.length > 0 ? top_session[0] : null,
                mapsPlayed: {
                    custom: map_ratio[0].custom,
                    official: map_ratio[0].official,
                    total: totalMapsCount,
                    percentageOfficial: Math.round(map_ratio[0].official / totalMapsCount * 100)
                }
            })
        }catch(err) {
            console.error('/api/user/:user/top',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/:user/sessions/:page', async (req, res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 10;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;
            const [rows] = await pool.query("SELECT * FROM stats_games WHERE steamid = ? ORDER BY id DESC LIMIT ?,?", [req.params.user, offset, perPage])
            const [total] = await pool.execute("SELECT COUNT(*) as count FROM stats_games WHERE steamid = ?", [req.params.user])
            res.json({
                sessions: rows,
                total: total[0].count
            })
        }catch(err) {
            console.error('/api/user/:user/totals/:gamemode',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/:user/averages', routeCache.cacheSeconds(120), async(req,res) => {
        if(!req.params.user) return res.status(404).json(null)
        try {
            const [totalSessions] = await pool.execute("SELECT (SELECT COUNT(*) as count FROM stats_games WHERE steamid = ?) as count, (SELECT COUNT(*) FROM `stats_games`) AS total_sessions", [req.params.user])
            const [deaths] = await pool.execute(`SELECT steamid,last_alias,minutes_played,survivor_deaths,survivor_ff,heal_others,revived_others,survivor_incaps FROM \`stats_users\` where steamid = ?`, [req.params.user])
            res.json({
                totalSessions: totalSessions[0].count,
                globalTotalSessions: totalSessions[0].total_sessions,
                ...deaths[0]
            });
        }catch(err) {
            console.error('[/api/user/:user/averages]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    return router;
}