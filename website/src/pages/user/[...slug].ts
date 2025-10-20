import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ url, redirect }) => {
    const rest = url.pathname.replace("/user", "/users")
    return redirect(rest)
}