require('dotenv').config();
const app = require('express')();

const WEB_PORT = process.env.WEB_PORT||8081;
const SPLIT_STATS_ROOTS = ['survivor','infected','pickups','tanks','damage','kills']
app.listen(WEB_PORT,() => {
    console.info('[Server] Listening on :' + WEB_PORT)
})

async function main() {
    const mysql = require('mysql2/promise');
    const pool = mysql.createPool({
        host:process.env.MYSQL_HOST||'localhost', 
        user: process.env.MYSQL_USER||'root', 
        password: process.env.MYSQL_PASSWORD,
        database: process.env.MYSQL_DB||'test'
    });
    // query database
    //const [rows, fields] = await connection.execute('SELECT * FROM `table` WHERE `name` = ? AND `age` > ?', ['Morty', 14]);
    app.get('/api/top',async(req,res) => {
        try {
            const [rows, fields] = await pool.execute("SELECT * FROM `stats` ORDER BY `survivor_damage_give` DESC LIMIT 10")
            res.json(rows);
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/top/daily',async(req,res) => {
        try {
            //TODO: add top_gamemode
            const [rows, fields] = await pool.execute("SELECT steamid,last_alias,minutes_played,points FROM `stats` ORDER BY `survivor_damage_give` DESC LIMIT 10")
            res.json(rows);
        }catch(err) {
            console.error('[/api/top/daily]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/user/:user',async(req,res) => {
        try {
            const [rows, fields] = await pool.execute("SELECT * FROM `stats` WHERE `last_alias` = ? OR `steamid` = ?", [req.params.user, req.params.user])
            if(rows.length > 0) {

                const [map_rows] = await pool.execute("SELECT map_name,difficulty_easy,difficulty_normal,difficulty_advanced,difficulty_expert,realism,wins  FROM `stats_maps` WHERE `steamid`= ?",[rows[0].steamid])
                /*let obj = {};
                for(const key in rows[0]) {
                    const split = key.split('_');
                    if(split.length >= 2 && (SPLIT_STATS_ROOTS.includes(split[0]) || split[1] === "used")) {
                        let root = split[0];
                        let new_key = split.slice(1,split.length).join("_")
                        if(new_key === "used") {
                            root = "used"
                            new_key = split[0]
                        }
                        if(!obj[root]) obj[root] = {}
                        obj[root][new_key] = rows[0][key]
                    }else{
                        obj[key] = rows[0][key]
                    }
                }*/

                res.json({
                    user:rows[0],
                    maps: map_rows
                })
            }else{
                res.json({user:null,maps:[]})
            }
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
};
main();
/* Routes 
/api/top
/api/user/:user
/api/maps/:user
*/