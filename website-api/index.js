require('dotenv').config();
const app = require('express')();

const WEB_PORT = process.env.WEB_PORT||8081;
app.listen(WEB_PORT,() => {
    console.info('[Server] Listening on :' + WEB_PORT)
})

const whitelist = process.env.CORS_WHITELIST ? process.env.CORS_WHITELIST.split(",") : []

//TODO: record random player of the day
//TODO: Possibly split some information to a cache total

async function main() {
    const mysql = require('mysql2/promise');
    const details = {
        socketPath: process.env.MYSQL_SOCKET_PATH,
        host:     process.env.MYSQL_HOST   || 'localhost', 
        database: process.env.MYSQL_DB     || 'test',
        user:     process.env.MYSQL_USER   || 'root', 
        password: process.env.MYSQL_PASSWORD
    }
    const pool = mysql.createPool(details);
    console.log('Connecting to', (details.socketPath || details.host), 'database', details.database)

    app.use((req, res, next) => {
        if(!req.headers.origin || whitelist.includes(req.headers.origin)) {
            res.header("Access-Control-Allow-Origin", '*');
        }
        next()
    })

    app.use('/api/user/',       require('./routes/user')(pool))
    app.use('/api/sessions',    require('./routes/sessions')(pool))
    app.use('/api/campaigns',   require('./routes/campaigns')(pool))
    app.use('/api/top',         require('./routes/top')(pool))
    app.use('/api/',            require('./routes/misc')(pool))
    
    app.get('*',(req,res) => {
        res.status(404).json({error:'PageNotFound'})
    })
    return pool;
};
module.exports = main()
