const router = require('express').Router();
const routeCache = require('route-cache');
module.exports = (pool) => {
    router.get('/users/:page?',async(req,res) => {
        try {
            const MAX_RESULTS = req.query.max_results ? parseInt(req.query.max_results) || 10 : 10;
    
            const selectedPage = req.params.page || 0;
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(req.params.page) - 1);
            const offset = pageNumber * MAX_RESULTS;
            const [rows] = await pool.query("SELECT steamid,last_alias,minutes_played,last_join_date,points FROM `stats_users` ORDER BY `points` DESC, `minutes_played` DESC LIMIT ?,?", [offset, MAX_RESULTS])
            res.json({
                users: rows,
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    router.get('/stats', routeCache.cacheSeconds(43200), async(req,res) => {
        try {
            const [deaths] = await pool.execute(`SELECT steamid,last_alias,points,survivor_deaths as value FROM \`stats_users\`  
                ORDER BY \`stats_users\`.\`survivor_deaths\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [ffDamage] = await pool.execute(`SELECT steamid,last_alias,points,survivor_ff as value FROM \`stats_users\`  
                ORDER BY \`stats_users\`.\`survivor_ff\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [healOthers] = await pool.execute(`SELECT steamid,last_alias,points,heal_others as value FROM \`stats_users\`  
                ORDER BY \`stats_users\`.\`heal_others\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [revivedOthers] = await pool.execute(`SELECT steamid,last_alias,points,revived_others as value FROM \`stats_users\`  
                ORDER BY \`stats_users\`.\`revived_others\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [survivorIncaps] = await pool.execute(`SELECT steamid,last_alias,points,survivor_incaps as value FROM \`stats_users\`  
                ORDER BY \`stats_users\`.\`survivor_incaps\` desc, \`stats_users\`.\`points\` desc limit 10`, []) 
            res.json({
                deaths,
                ffDamage,
                healOthers,
                revivedOthers,
                survivorIncaps
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    return router;
}