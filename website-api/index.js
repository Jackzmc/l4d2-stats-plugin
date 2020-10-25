require('dotenv').config();
const app = require('express')();

const WEB_PORT = process.env.WEB_PORT||8081;
app.listen(WEB_PORT,() => {
    console.info('[Server] Listening on :' + WEB_PORT)
})

//TODO: record random player of the day

async function main() {
    const mysql = require('mysql2/promise');
    const pool = mysql.createPool({
        host: process.env.MYSQL_HOST || 'localhost', 
        user: process.env.MYSQL_USER || 'root', 
        password: process.env.MYSQL_PASSWORD,
        database: process.env.MYSQL_DB || 'test'
    });
    // query database
    //const [rows, fields] = await connection.execute('SELECT * FROM `table` WHERE `name` = ? AND `age` > ?', ['Morty', 14]);
    app.get('/api/top/:page?',async(req,res) => {
        try {
            const selectedPage = req.params.page || 0;
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(req.params.page) - 1);
            const offset = pageNumber * 10;
            const [rows] = await pool.execute("SELECT steamid,last_alias,minutes_played,points FROM `stats` ORDER BY `points` DESC, `minutes_played` DESC LIMIT ?,10", [offset])
            const [count] = await pool.execute("SELECT COUNT(*) AS total FROM `stats` ");
            res.json({
                users: rows,
                total_users: count[0].total
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/search/:user',async(req,res) => {
        try {
            //TODO: add top_gamemode
            const searchQuery = `%${req.params.user}%`;
            const [rows] = await pool.execute("SELECT steamid,last_alias,minutes_played,points FROM `stats` WHERE `last_alias` LIKE ?", [ searchQuery ])
            res.json(rows);
        }catch(err) {
            console.error('[/api/search/:user]', err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/maps/',async(req,res) => {
        try {
            const [rows] = await pool.execute("SELECT map_name,wins FROM `stats_maps` GROUP BY map_name ORDER BY `wins` DESC ")
            res.json({
                maps: rows
            })
        }catch(err) {
            console.error('[/api/maps]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/maps/:map',async(req,res) => {
        try {
            const [rows] = await pool.execute("SELECT * FROM `stats_maps` WHERE `map_name` = ? ", [req.params.map.toLowerCase()])
            let bestMap = { best_time: -1};
            let totals = {
                wins: 0,
                easy: 0, 
                normal: 0,
                advanced: 0,
                expert: 0,
                realism: 0
            }
            rows.forEach(map => {
                if(bestMap.best_time < map.best_time) {
                    bestMap = map;
                }
                for(const total in totals) {
                    if(map[total] > 0)
                        totals[total] += map[total]
                }
            })
            res.json({
                best: bestMap,
                totals
            })
        }catch(err) {
            console.error('[/api/maps]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/user/:user',async(req,res) => {
        const user = req.params.user.replace(/\+-/,' ')

        try {
            const [rows] = await pool.execute("SELECT * FROM `stats` WHERE STRCMP(`last_alias`,?) = 0 OR `steamid` = ?", [user, req.params.user])
            if(rows.length > 0) {
                const [map_rows] = await pool.execute("SELECT map_name,difficulty_easy,difficulty_normal,difficulty_advanced,difficulty_expert,realism,wins FROM `stats_maps` WHERE `steamid`= ?", [rows[0].steamid])

                res.json({
                    user:rows[0],
                    maps: map_rows
                })
            }else{
                res.json({ 
                    user: null, 
                    maps: [], 
                    not_found: true 
                })
            }
        }catch(err) {
            console.error('[/api/user/:user]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/user/:user/campaign',async(req,res) => {
        try {
            const [rows] = await pool.execute("SELECT SUM(`wins`) AS wins, SUM(`difficulty_easy`) AS easy, SUM(`difficulty_normal`) AS normal, SUM(`difficulty_advanced`) AS advanced, SUM(`difficulty_expert`) AS expert, SUM(`realism`) AS realism FROM `stats_maps` WHERE `steamid`=?",[req.params.user])
            if(rows.length > 0) {
                let stats = {};
                for(const key in rows[0]) stats[key] = parseInt(rows[0][key])
                res.json({campaign: stats})
            }else{
                res.json({camapign: {}, not_found: true})
            }
        }catch(err) {
            console.error('/api/user/:user/campaign',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    app.get('/api/user/:user/sessions/:page?',async(req,res) => {
        try {
            const selectedPage = req.params.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(req.params.page) - 1);
            const offset = pageNumber * 10;
            const [rows] = await pool.execute("SELECT * FROM `stats_games` WHERE `steamid`=? LIMIT ?,15", [ req.params.user, offset ])
            res.json(rows)
        }catch(err) {
            console.error('/api/user/:user/campaign',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    app.get('/api/*',(req,res) => {
        res.status(404).json({error:'PageNotFound'})
    })
};
main();