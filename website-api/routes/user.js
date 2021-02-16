const router = require('express').Router();
module.exports = (pool) => {
    router.get('/:user',async(req,res) => {
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
    return router;
}