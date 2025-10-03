import Mysql from 'mysql2/promise'

const dbUrl = import.meta.env.DATABASE_URL

if(!dbUrl) {
    throw new Error("Missing env variable DATABASE_URL")
}

console.info("[Pool] Connecting to database")
const pool = Mysql.createPool(dbUrl)

export default pool