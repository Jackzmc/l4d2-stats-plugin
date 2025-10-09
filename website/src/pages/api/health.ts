import cache from "@/db/cache.ts";
import { apiJson } from "@/utils/api.ts";
import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ params, request, url }) => {
    return apiJson({
        health: "healthy",
        uptime: process.uptime(),
        mem: process.memoryUsage(),
        cache: cache.stats,
    })
}