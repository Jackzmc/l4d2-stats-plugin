import Router from 'express'
const router = Router()
import routeCache from 'route-cache'

export default function(pool) {
    router.get('/values', routeCache.cacheSeconds(600), async(req, res) => {
        const [gamemodes] = await pool.query("SELECT gamemode, COUNT(gamemode) count from stats_games GROUP BY gamemode ORDER BY count DESC")
        res.json({
            gamemodes
        })
    })
    router.get('/:id', routeCache.cacheSeconds(120), async(req,res) => {
        try {
            const [rows] = await pool.query(
                "SELECT `stats_games`.*, last_alias, points, i.name as map_name FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid INNER JOIN map_info i ON i.mapid = stats_games.map WHERE left(`stats_games`.campaignID, 8) = ? ORDER BY SpecialInfectedKills desc, SurvivorDamage asc, ZombieKills desc, DamageTaken asc", 
                [req.params.id.substring(0,8)]
            )
            res.json(rows)
        }catch(err) {
            console.error('[/api/user/:user]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    router.get('/', routeCache.cacheSeconds(60), async(req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 4;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;

            const difficulty         = isNaN(req.query.difficulty) ? null : parseInt(req.query.difficulty)
            let selectTag            = req.query.tag
            if(!selectTag || selectTag === "any") selectTag = "prod"
            let gamemodeSearchString = req.query.gamemode && req.query.gamemode !== "all" ? `${req.query.gamemode}` : `%`
            let mapSearchString      = "" // RLIKE "^c[0-9]m"
            if(req.query.type) {
                if(req.query.type.toLowerCase() === "official") mapSearchString = `AND map RLIKE "^c[0-9]+m"`
                else if(req.query.type.toLowerCase() === "custom") mapSearchString = `AND map NOT RLIKE "^c[0-9]+m"`
            }

            const [total] = await pool.execute("SELECT COUNT(DISTINCT campaignID) as total FROM `stats_games`")
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
                    server_tags,
                    i.name as map_name
                FROM \`stats_games\` as g 
                INNER JOIN \`stats_users\` ON g.steamid = \`stats_users\`.steamid 
                INNER JOIN map_info i ON i.mapid = g.map
                WHERE FIND_IN_SET(?, server_tags) ${mapSearchString} AND gamemode LIKE ? AND ? IS NULL OR difficulty = ?
                GROUP BY g.campaignID 
                ORDER BY date_end DESC LIMIT ?, ?`, 
            [selectTag, gamemodeSearchString, difficulty, difficulty, offset, perPage])
            res.json({
                meta: {
                    selectTag,
                    gamemodeSearchString,
                    mapSearchString,
                    difficulty
                },
                recentCampaigns: recent,
                total_campaigns: total[0].total
            })
        }catch(err) {
            console.error('[/api/user/:user]',err.stack);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    return router;
}