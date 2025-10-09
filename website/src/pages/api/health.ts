import cache from "@/db/cache.ts";
import { apiJson } from "@/utils/api.ts";
import type { APIRoute } from "astro";

import { metrics } from '@/middleware.ts' 

export const GET: APIRoute = async ({ params, request, url }) => {
    return apiJson({
        health: "healthy",
        uptime: process.uptime(),
        mem: process.memoryUsage(),
        cache: cache.stats,
        metrics
    })
}