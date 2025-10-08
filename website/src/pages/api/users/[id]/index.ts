import { apiJson } from "@/utils/api.ts";
import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ params, request, url }) => {
    return apiJson({}, 501)
}