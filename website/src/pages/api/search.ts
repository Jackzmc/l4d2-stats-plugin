import { searchUsers } from "@/models/User.ts";
import { apiError, apiJson } from "@/utils/api.ts";
import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ params, request, url }) => {
    let query = url.searchParams.get("q")
    if(!query) return apiError(400, "BAD_REQUEST", "Missing ?q")
    query = query.toLowerCase()

    const users = await searchUsers(query, 6)
    return apiJson(users)
}