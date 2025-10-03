import type { RowDataPacket } from "mysql2";
import db from "../db/pool.ts";

export async function getLeaderboard(page: number) {
    const [rows] = await db.query<RowDataPacket[]>("SELECT * FROM stats_users LIMIT 5 ")
    console.log(rows)
    return rows
}