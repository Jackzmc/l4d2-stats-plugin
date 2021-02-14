require('dotenv').config();
const app = require('express')();

const WEB_PORT = process.env.WEB_PORT||8081;
app.listen(WEB_PORT,() => {
    console.info('[Server] Listening on :' + WEB_PORT)
})

const DIFFICULTIES = ["easy","normal","advanced","expert"]


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
    app.get('/api/info',async(req,res) => {
        try {
            const [totals] = await pool.execute("SELECT (SELECT COUNT(*) FROM `stats_users`) AS total_users, (SELECT COUNT(*) FROM `stats_games`) AS total_sessions");
            res.json({
                ...totals[0]
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/top/users/:page?',async(req,res) => {
        try {
            const MAX_RESULTS = req.query.max_results ? parseInt(req.query.max_results) || 10 : 10;

            const selectedPage = req.params.page || 0;
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(req.params.page) - 1);
            const offset = pageNumber * MAX_RESULTS;
            const [rows] = await pool.execute("SELECT steamid,last_alias,minutes_played,last_join_date,points FROM `stats_users` ORDER BY `points` DESC, `minutes_played` DESC LIMIT ?,?", [offset, MAX_RESULTS])
            res.json({
                users: rows,
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/top/stats',async(req,res) => {
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
    app.get('/api/user/:user/averages',async(req,res) => {
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
            console.error('[/api/:user/averages]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/search/:user',async(req,res) => {
        try {
            //TODO: add top_gamemode
            if(!req.params.user) return res.status(404).json([])
            const searchQuery = `%${req.params.user}%`;
            const [rows] = await pool.execute("SELECT steamid,last_alias,minutes_played,last_join_date,points FROM `stats_users` WHERE `last_alias` LIKE ?", [ searchQuery ])
            res.json(rows);
        }catch(err) {
            console.error('[/api/search/:user]', err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/campaigns/:id', async(req,res) => {
        try {
            const [rows] = await pool.execute("SELECT `stats_games`.*,last_alias,points FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid  WHERE left(`stats_games`.campaignID,8) = ? ORDER BY SpecialInfectedKills desc, SurvivorDamage asc, ZombieKills desc, DamageTaken asc", [req.params.id.substring(0,8)])
            res.json(rows)
        }catch(err) {
            console.error('[/api/user/:user]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/campaigns', async(req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 4;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;

            let selectTag            = req.query.tag || "prod"
            let gamemodeSearchString = req.query.gamemode && req.query.gamemode !== "all" ? `${req.query.gamemode}` : `%`
            let mapSearchString      = "" // RLIKE "^c[0-9]m"
            if(req.query.type) {
                if(req.query.type.toLowerCase() === "official") mapSearchString = `AND map RLIKE "^c[0-9]m"`
                else if(req.query.type.toLowerCase() === "custom") mapSearchString = `AND map NOT RLIKE "^c[0-9]m"`
            }

            const [total] = await pool.execute("SELECT COUNT(dISTINCT campaignID) as total FROM `stats_games`")
            const [recent] = await pool.execute(`
                SELECT COUNT(g.campaignID) as playerCount, 
                    g.campaignID,
                    g.map, 
                    g.date_start, 
                    g.date_end, 
                    difficulty, 
                    gamemode,SUM(ZombieKills) as CommonsKilled, 
                    SUM(SurvivorDamage) as FF, 
                    SUM(Deaths) as Deaths, 
                    SUM(MedkitsUsed), 
                    (SUM(MolotovsUsed) + SUM(PipebombsUsed) + SUM(BoomerBilesUsed)) as ThrowableTotal, 
                    server_tags 
                FROM \`stats_games\` as g INNER JOIN \`stats_users\` ON g.steamid = \`stats_users\`.steamid 
                WHERE FIND_IN_SET(?, server_tags) ${mapSearchString} AND gamemode LIKE ?
                GROUP BY g.campaignID 
                ORDER BY date_end DESC LIMIT ?, ?`, 
            [selectTag, gamemodeSearchString, offset, perPage])
            res.json({
                meta: {
                    selectTag,
                    gamemodeSearchString,
                    mapSearchString,
                },
                recentCampaigns: recent,
                total_campaigns: total[0].total
            })
        }catch(err) {
            console.error('[/api/user/:user]',err.stack);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    app.get('/api/user/:user',async(req,res) => {
        const user = req.params.user.replace(/\+-/,' ')

        try {
            const [rows] = await pool.execute("SELECT * FROM `stats_users` WHERE STRCMP(`last_alias`,?) = 0 OR `steamid` = ?", [user, req.params.user])
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
    app.get('/api/user/:user/totals/:gamemode',async(req,res) => {
        try {
            const [rows] = await pool.execute("SELECT `map`, `difficulty` FROM `stats_games` WHERE `steamid` = ? AND `gamemode` = ?", [req.params.user, req.params.gamemode])
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
    app.get('/api/totals', async(req,res) => {
        try {
            const [totals] = await pool.execute(`SELECT 
            sum(nullif(finale_time,0)) as finale_time, 
            sum(date_end - date_start) as game_duration,
            sum(nullif(ZombieKills,0)) as zombie_kills, 
            sum(nullif(SurvivorDamage,0)) as survivor_ff, 
            sum(MedkitsUsed) as MedkitsUsed, 
            sum(FirstAidShared) as FirstAidShared,
            sum(PillsUsed) as PillsUsed, 
            sum(AdrenalinesUsed) as AdrenalinesUsed,
            sum(MolotovsUsed) as MolotovsUsed, 
            sum(PipebombsUsed) as PipebombsUsed, 
            sum(BoomerBilesUsed) as BoomerBilesUsed, 
            sum(DamageTaken) as DamageTaken, 
            sum(MeleeKills) as MeleeKills, 
            sum(ReviveOtherCount) as ReviveOtherCount, 
            sum(DefibrillatorsUsed) as DefibrillatorsUsed,
            sum(Deaths) as Deaths, 
            sum(Incaps) as Incaps, 
            sum(nullif(boomer_kills,0)) as boomer_kills, 
            sum(nullif(jockey_kills,0)) as jockey_kills, 
            sum(nullif(smoker_kills,0)) as smoker_kills, 
            sum(nullif(spitter_kills,0)) as spitter_kills, 
            sum(nullif(hunter_kills,0)) as hunter_kills,
            sum(nullif(charger_kills,0)) as charger_kills,
            (SELECT COUNT(*) FROM \`stats_games\`) AS total_sessions,
            (SELECT COUNT(distinct(campaignID)) from stats_games) AS total_games,
            (SELECT COUNT(*) FROM \`stats_users\`) AS total_users
            FROM stats_games`)
            const [mapTotals] = await pool.execute("SELECT map,COUNT(*) as count FROM stats_games GROUP BY map ORDER BY COUNT(map) DESC")
            if(totals.length == 0) {
                return res.status(500).json({error:'Internal Server Error'})
            }else{
                let stats = {}, maps = {};
                for(const key in totals[0]) {
                    stats[key] = parseInt(totals[0][key])
                }
                mapTotals.forEach(({map,count}) => {
                    maps[map] = count;
                })
                res.json({
                    stats,
                    maps
                })
            }
        }catch(err) {
            console.error('/api/totals',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    app.get('/api/summary', async(req,res) => {
        try {
            const [maps] = await pool.execute("SELECT map FROM stats_games GROUP BY map ORDER BY COUNT(map) DESC")
            const [userCount] = await pool.execute("SELECT AVG(games.players) as avgPlayers FROM (SELECT COUNT(campaignID) as players FROM stats_games GROUP BY `campaignID`) as games")
            const [topStats] = await pool.execute(`SELECT 
            avg(nullif(finale_time,0)) as finale_time, 
            avg(date_end - date_start) as game_duration,
            avg(nullif(ZombieKills,0)) as zombie_kills, 
            avg(nullif(SurvivorDamage,0)) as survivor_ff, 
            avg(MedkitsUsed) as MedkitsUsed, 
            avg(FirstAidShared) as FirstAidShared,
            avg(PillsUsed) as PillsUsed, 
            avg(AdrenalinesUsed) as AdrenalinesUsed,
            avg(MolotovsUsed) as MolotovsUsed, 
            avg(PipebombsUsed) as PipebombsUsed, 
            avg(BoomerBilesUsed) as BoomerBilesUsed, 
            avg(DamageTaken) as DamageTaken, 
            avg(difficulty) as difficulty, 
            avg(MeleeKills) as MeleeKills, 
            avg(ping) as ping, 
            avg(ReviveOtherCount) as ReviveOtherCount, 
            avg(DefibrillatorsUsed) as DefibrillatorsUsed,
            avg(Deaths) as Deaths, 
            avg(Incaps) as Incaps, 
            avg(nullif(boomer_kills,0)) as boomer_kills, 
            avg(nullif(jockey_kills,0)) as jockey_kills, 
            avg(nullif(smoker_kills,0)) as smoker_kills, 
            avg(nullif(spitter_kills,0)) as spitter_kills, 
            avg(nullif(hunter_kills,0)) as hunter_kills,
            avg(nullif(charger_kills,0)) as charger_kills
            FROM stats_games`)
            if(topStats.length == 0 || maps.length == 0 || userCount.length == 0) {
                return res.status(500).json({error:'Internal Server Error'})
            }else{
                let stats = {};
                for(const key in topStats[0]) {
                    if(key == "difficulty") {
                        stats[key] = Math.round(parseFloat(topStats[0][key]))
                    }else{
                        stats[key] = parseFloat(topStats[0][key])
                    }
                }
                res.json({
                    topMap: maps[0].map,
                    bottomMap: maps[maps.length-1].map,
                    averagePlayers: Math.round(parseFloat(userCount[0].avgPlayers)),
                    stats
                })
            }
        }catch(err) {
            console.error('/api/summary',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    app.get('/api/user/:user/totals',async(req,res) => {
        try {
            const [rows] = await pool.execute("SELECT `map`, `difficulty`, `gamemode` FROM `stats_games` WHERE `steamid` = ?",[req.params.user])
            if(rows.length > 0) {
                let mapStat = {};
                let difficulty = {
                    easy: 0,
                    normal: 0,
                    advanced: 0,
                    expert: 0
                }
                let gamemodes = {
                    realism: 0,
                    coop: 0,
                    versus: 0,
                    mutation: 0
                }
                rows.forEach(row => {
                    if(!mapStat[row.map]) mapStat[row.map] = {
                        difficulty: {
                            easy: 0,
                            normal: 0,
                            advanced: 0,
                            expert: 0
                        },
                        gamemodes: {
                            realism: 0,
                            coop: 0,
                            versus: 0,
                        },
                        wins: 0
                    }
                    mapStat[row.map].wins++;
                    const diff = DIFFICULTIES[row.difficulty];
                    let gamemode = row.gamemode || 'coop';
                    if(gamemode.startsWith("mutation") || gamemode == "tankrun" || gamemode == "rocketdude") gamemode = 'mutation';
                    mapStat[row.map].difficulty[diff]++;
                    difficulty[diff]++;
                    if(mapStat[row.map].gamemodes[gamemode]) {
                        gamemodes[gamemode]++;
                        mapStat[row.map].gamemodes[gamemode]++;
                    }else {
                        gamemodes['coop']++;
                        mapStat[row.map].gamemodes['coop']++;
                    }
                })
                const mapTotals = [];
                for(const map in mapStat) {
                    mapTotals.push({
                        map,
                        ...mapStat[map]
                    })
                }
                res.json({
                    totals: {
                        wins: rows.length,
                        gamemodes,
                        difficulty
                    }, 
                    maps: mapTotals,
                })
            }else{
                res.json({camapign: {}, not_found: true})
            }
        }catch(err) {
            console.error('/api/user/:user/totals',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    app.get('/api/user/:user/times',async(req,res) => {
        //SELECT id,steamid,campaignID,map,date_end - date_start AS duration FROM `stats_games` WHERE `date_start` IS NOT NULL AND steamid = ? ORDER BY duration desc 
        try {
            const [times] = await pool.execute("SELECT id,steamid,campaignID,map,date_end - date_start AS duration FROM `stats_games` WHERE `date_start` IS NOT NULL AND steamid = ? GROUP BY map ORDER BY duration asc",[req.params.user])
            res.json({
                times
            })
        }catch(err) {
            console.error('/api/user/:user/times',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    app.get('/api/user/:user/sessions/:page?',async(req,res) => {
        try {
            const selectedPage = req.params.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(req.params.page) - 1);
            const offset = pageNumber * 10;
            const [rows] = await pool.execute("SELECT * FROM `stats_games` WHERE `steamid`=? LIMIT ?,15", [ req.params.user, offset ])
            const [total_sessions] = await pool.execute("SELECT COUNT(*) AS total FROM `stats_games` WHERE `steamid`=?", [ req.params.user])
            res.json({
                sessions: rows,
                total: total_sessions[0].total
            })
        }catch(err) {
            console.error('/api/user/:user/sessions/:page?',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    app.get('/api/sessions', async(req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 10;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;
            const [rows] = await pool.execute("SELECT `stats_games`.*,last_alias,points FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid order by `stats_games`.id asc LIMIT ?,?", [offset, perPage])
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
    app.get('/api/sessions/:session', async(req,res) => {
        try {
            const sessId = parseInt(req.params.session);
            if(isNaN(sessId)) {
                res.status(422).json({error: "Session ID is not a valid number."})
            }else{
                const [row] = await pool.execute("SELECT `stats_games`.*,last_alias,points FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid WHERE `stats_games`.`id`=?", [req.params.session])
                if(row.length > 0) {
                    let users = [];
                    if(row[0].campaignID) {
                        const [userlist] = await pool.execute("SELECT stats_games.id,stats_users.steamid,stats_users.last_alias from `stats_games` inner join `stats_users` on `stats_users`.steamid = `stats_games`.steamid WHERE `campaignID`=?", [row[0].campaignID])
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
    app.get('/api/*',(req,res) => {
        res.status(404).json({error:'PageNotFound'})
    })
};
main();
