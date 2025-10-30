import { getMapInfo } from "@/models/Map.ts";
import { apiError, apiJson } from "@/utils/api.ts";
import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ params, request, url }) => {
    if(!params.id) return apiError(400, "MISSING_PARAM", "Missing 'id' param")

    const map = await getMapInfo(params.id)
    if(!map) return apiError(404, "MAP_NOT_FOUND", "No map found with specified ID. Maps are based on their finale chapter mapid.")

    return apiJson(map)
}