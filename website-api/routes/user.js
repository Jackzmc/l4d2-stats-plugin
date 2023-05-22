const router = require('express').Router();
const routeCache = require('route-cache');
const fetch = require('node-fetch')

const Canvas = require('canvas')

Canvas.registerFont('./assets/fonts/OpenSans-Light.ttf', { family: 'OpenSans', weight: 'Light' })
Canvas.registerFont('./assets/fonts/micross.ttf', { family: 'MS-Sans-Serif' })
Canvas.registerFont('./assets/fonts/Roboto-Bold.ttf', { family: 'Roboto', weight: 'Bold'})

const SurvivorMap = {
    0: 'nick',
    1: 'rochelle',
    2: 'ellis',
    3: 'coach',
    4: 'bill',
    5: 'zoey',
    6: 'francis',
    7: 'louis'
}

const { weapons: WeaponNames } = require('../assets/item_names.json')

const Maps = {
    "c1m": "Dead Center",
    "c2m": "Dark Carnival",
    "c3m": "Swamp Fever",
    "c4m": "Hard Rain",
    "c5m": "The Parish",
    "c6m": "The Passing",
    "c7m": "The Sacrifice",
    "c8m": "No Mercy",
    "c9m": "Crash Course",
    "c10": "Death Toll",
    "c11": "Dead Air",
    "c12": "Blood Harvest",
    "c13": "Cold Stream",
    "c14": "Last Stand"
}

const DIFFICULTIES = [
    "Easy", "Normal", "Advanced", "Expert"
]

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
            let bits = req.params.user.split(":")
            bits = bits[bits.length - 1]
            const [rows] = await pool.query(
                "SELECT * FROM `stats_users` WHERE STRCMP(`last_alias`,?) = 0 OR `steamid` LIKE CONCAT('STEAM_%:%:', ?)", 
                [user, bits]
            )
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
    router.get('/:user/weapons', async(req,res) => {
        const user = req.params.user.replace(/\+-/,' ')

        try {
            const [rows] = await pool.query(
                "SELECT weapon, minutesUsed, totalDamage, headshots, kills FROM `stats_weapons_usage` WHERE `steamid` = ?", 
                [user]
            )
            return res.json({
                weapons: rows
            })
        }catch(err) {
            console.error('[/api/user/:user/weapons]' ,err.message);
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
                    const diff = DIFFICULTIES[row.difficulty].toLowerCase();
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
            console.error('/api/user/:user/totals/:gamemode',req.params.gamemode, err.message)
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
            const userInfo = await getUserStats(req.params.user)
            const [top_session] = await pool.execute("SELECT *, map, date_end - date_start as difference FROM stats_games WHERE date_end > 0 AND date_start > 0 AND steamid = ? ORDER BY difference ASC LIMIT 10", [req.params.user])
            res.json({
                topMap: userInfo.top.map,
                topCharacter: userInfo.top.character,
                topWeapon: userInfo.top.weapon.name,
                bestSessionByTime: top_session.length > 0 ? top_session.find(session => session.difference > 300) : null,
                mapsPlayed: {
                    custom: userInfo.maps.custom,
                    official: userInfo.maps.official,
                    total: userInfo.maps.total,
                    percentageOfficial: Math.round(userInfo.maps.official / userInfo.maps.total * 100)
                }
            })
        }catch(err) {
            console.error('/api/user/:user/top',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
 
    router.get('/:user/points/:page', async (req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 50;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.params.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;
            const [rows] = await pool.query("SELECT timestamp, type, amount FROM stats_points WHERE steamid = ? ORDER BY id DESC LIMIT ?,?", [req.params.user, offset, perPage])
            const [total] = await pool.execute("SELECT COUNT(*) as count FROM stats_points WHERE steamid = ?", [req.params.user])
            res.json({
                history: rows,
                total: total[0].count
            })
        }catch(err) {
            console.error('/api/user/:user/sessions/:page',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/:user/sessions/:page', async (req, res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 10;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.params.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;
            const [rows] = await pool.query("SELECT * FROM stats_games WHERE steamid = ? ORDER BY id DESC LIMIT ?,?", [req.params.user, offset, perPage])
            const [total] = await pool.execute("SELECT COUNT(*) as count FROM stats_games WHERE steamid = ?", [req.params.user])
            res.json({
                sessions: rows,
                total: total[0].count
            })
        }catch(err) {
            console.error('/api/user/:user/sessions/:page',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/:user/averages', routeCache.cacheSeconds(120), async(req,res) => {
        if(!req.params.user) return res.status(404).json(null)
        try {
            const [totalSessions] = await pool.execute("SELECT (SELECT COUNT(*) as count FROM stats_games WHERE steamid = ?) as count, (SELECT COUNT(*) FROM `stats_games`) AS total_sessions", [req.params.user])
            const [stats] = await pool.execute(`SELECT steamid,last_alias,minutes_played,survivor_deaths,survivor_ff,heal_others,revived_others,survivor_incaps,minutes_idle FROM \`stats_users\` where steamid = ?`, [req.params.user])
            res.json({
                totalSessions: totalSessions[0].count,
                globalTotalSessions: totalSessions[0].total_sessions,
                ...stats[0]
            });
        } catch(err) {
            console.error('[/api/user/:user/averages]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    router.get('/:user/image', routeCache.cacheSeconds(600), async(req, res) => {
        if(!req.params.user) return res.status(404).json(null)
        try {
            const { top, name, maps, stats } = await getUserStats(req.params.user)

            if(!top.characterName || !name) {
                return res.status(404).json({ error: 'User not found, or missing stats' })
            }

            const canvas = Canvas.createCanvas(588, 194)
            const ctx = canvas.getContext('2d')

            const playStyle = await getPlayStyle(req.params.user)
            if(req.query.gradient !== undefined) {
                const bannerBase = await Canvas.loadImage(`assets/banner-base.png`)
                ctx.drawImage(bannerBase, 0, 0, canvas.width, canvas.height)
            }

            const survivorImg = await Canvas.loadImage(`assets/fullbody/${top.characterName.toLowerCase()}.png`)
            ctx.drawImage(survivorImg, 0, 0, 120, 194)

            ctx.font = 'bold 20pt "Roboto", Symbola, Joanna, Helvetica Now, Helvetica, Arial, Tahoma, Segoe UI, Segoe UI Historic, Segoe UI Symbol, Segoe UI Emoji, Cambria Math, Abyssinica SIL, DaunPehn, David, DokChampa, Ebrima, Estrangelo Edessa, Ethiopia Jiret, Gadugi, GF Zemen Unicode, Gulim, Han Nom A, Javanese Text, Lao UI, Leelawadee UI, Kartika, Khmer UI, Malgun Gothic, Mangal, Meiryo, Microsoft New Tai Lue'
            ctx.fillStyle = '#cc105f'
            ctx.fillText(name, 120, 40)

            ctx.font = '16pt Sans'
            ctx.fillStyle = '#5c5e5e'
            ctx.fillText(playStyle.name, 120, 60)

            setLine(ctx, 'Top Weapon: ', top.weapon.name || top.weapon.id, 120, 90)
            setLine(ctx, 'Top Map: ', top.map.name || top.map.id, 120, 111)
            ctx.fillText(`${maps.total.toLocaleString()} Games Played (${Math.round(maps.official/maps.total*100)}% official)`, 120, 132)
            ctx.fillText(`${stats.witchesCrowned.toLocaleString()} witches crowned`, 120, 153)
            ctx.fillText(`${stats.clownsHonked.toLocaleString()} clowns honked`, 120, 174)

            ctx.font = 'light 8pt "arial"'
            ctx.fillStyle = '#737578'
            ctx.fillText('stats.jackz.me', canvas.width - 72, canvas.height - 8)

            res.set('Content-Type', 'image/png')
            canvas.createPNGStream().pipe(res)
        } catch(err) {
            console.error('[/api/user/:user/image]',err.stack);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    function setLine(ctx, header, value, x, y) {
        ctx.font = 'bold 14pt Arial'
        ctx.fillStyle = '#1e1f1e'
        const twS = ctx.measureText(header)
        ctx.fillText(header, x, y, twS.width)
        ctx.font = '16pt Arial'
        ctx.fillText(value, x + twS.width, y)
    }
    async function getUserStats(user) {
        let [row] = await pool.execute("SELECT characterType as k, COUNT(*) as count FROM `stats_games` WHERE steamid = ? AND characterType IS NOT NULL GROUP BY `characterType` ORDER BY count DESC LIMIT 1", [user]);
        const topCharacter = row.length > 0 ? SurvivorMap[row[0].k] : null;
        [row] = await pool.execute("SELECT last_alias, witches_crowned, clowns_honked from stats_users WHERE steamid = ?", [user]);
        const stats = row.length > 0 ? row[0] : {};
        [row] = await pool.execute("SELECT map as k, COUNT(*) as count FROM `stats_games` WHERE steamid = ? GROUP BY `map` ORDER BY count desc", [user]);
        const topMap = row.length > 0 ? row[0] : null;
        [row] = await pool.execute("SELECT top_weapon as k, COUNT(*) as count FROM `stats_games` WHERE steamid = ? AND top_weapon IS NOT NULL AND top_weapon != '' GROUP BY `top_weapon` ORDER BY count DESC LIMIT 1 ", [user]);
        const topWeapon = row.length > 0 ? (row[0]?.k).replace('weapon_','') : null;
        [row] = await pool.execute('SELECT (SELECT COUNT(*) FROM `stats_games` WHERE `steamid` = ? AND `map` NOT RLIKE "^c[0-9]+m") as custom,  (SELECT COUNT(*) FROM `stats_games` WHERE `steamid` = ? AND `map` RLIKE "^c[0-9]+m") as official FROM `stats_games` LIMIT 1', [user, user]);
        const maps = {
            official: row[0].official,
            custom: row[0].custom,
            total: row[0].custom + row[0].official,
        }
        return {
            top: {
                characterName: topCharacter,
                map: {
                    id: topMap?.k,
                    count: topMap?.count,
                    name: topMap ? Maps[topMap.k.slice(0,3)] : null
                },
                weapon: {
                    id: topWeapon,
                    name: topWeapon ? WeaponNames[topWeapon] : null
                }
            },
            stats: {
                witchesCrowned: stats.witches_crowned,
                clownsHonked: stats.clowns_honked
            },
            maps,
            name: stats.last_alias
        }
    }

    async function getPlayStyle(user) {
        const res = await fetch(`https://jackz.me/l4d2/scripts/analyze.php?steamid=${user}&concise=1`)
        if(res.ok) {
            const { result } = await res.json()
            return result
        } else {
            return null
        }
    }

    return router;
}