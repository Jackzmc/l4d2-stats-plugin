require('dotenv').config();
const app = require('express')();

const WEB_PORT = process.env.WEB_PORT||8081;
app.listen(WEB_PORT,() => {
    console.info('[Server] Listening on :' + WEB_PORT)
})

const DIFFICULTIES = ["easy","normal","advanced","expert"]


//TODO: record random player of the day
//TODO: Possibly split some information to a cache total

async function main() {
    const mysql = require('mysql2/promise');
    const pool = mysql.createPool({
        host:     process.env.MYSQL_HOST   || 'localhost', 
        database: process.env.MYSQL_DB     || 'test',
        user:     process.env.MYSQL_USER   || 'root', 
        password: process.env.MYSQL_PASSWORD
    });

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
