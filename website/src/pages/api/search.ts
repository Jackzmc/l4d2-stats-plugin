import { searchUsers } from "@/models/User.ts";
import { apiError, apiJson } from "@/utils/api.ts";
import type { APIRoute } from "astro";

const SEARCH_LIMIT = 20

export const GET: APIRoute = async ({ params, request }) => {
    const url = new URL(request.url)
    let query = url.searchParams.get("q")
    if(!query) return apiError(400, "BAD_REQUEST", "Missing ?q")
    query = query.toLowerCase()

    const users = await searchUsers(query, SEARCH_LIMIT)
    return apiJson(users)
}