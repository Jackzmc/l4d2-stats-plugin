import { getUser } from "@/models/User.ts";
import { apiError, apiJson } from "@/utils/api.ts";
import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ params, request, url }) => {
    if(!params.id) return apiError(400, "MISSING_PARAM", "Missing 'id' param")
    const user = await getUser(params.id)
    if(!user) return apiError(404, "USER_NOT_FOUND", "No user found")
    return apiJson(user)
}