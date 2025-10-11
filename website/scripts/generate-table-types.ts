import { Client } from '@rmp135/sql-ts'
import 'dotenv/config'
import { writeFileSync } from 'fs'
import path from 'path'

if(!process.env.DATABASE_URL) {
    throw new Error("Missing env 'DATABASE_URL'")
}

const config = {
    client: 'mysql2',
    connection: process.env.DATABASE_URL,
    tableNameCasing: "pascal",
    schemas: ["left4dead2"],
    tables: [
        "left4dead2.stats_map_info",
        "left4dead2.stats_map_ratings",
        "left4dead2.stats_games",
        "left4dead2.stats_heatmaps",
        "left4dead2.stats_points",
        "left4dead2.stats_users",
        "left4dead2.stats_weapon_usages",
    ]
} 

const definition = await Client
  .fromConfig(config)
  .fetchDatabase()
  .toTypescript()

writeFileSync(path.join(import.meta.dirname, '../src/db/types.ts'), definition)

console.log(definition)