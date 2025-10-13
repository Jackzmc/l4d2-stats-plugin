import { defineMiddleware } from "astro:middleware";

const CORS_ALLOW_LIST = process.env.API_ALLOWED_ORIGINS ? process.env.API_ALLOWED_ORIGINS.split(",") : [""]
const CORS_ALLOW_ANY = CORS_ALLOW_LIST[0] === "*"

console.info("[Cors] Allowed Origins:", CORS_ALLOW_ANY ? "-any-" : CORS_ALLOW_LIST.join(" "))

export const metrics = {
    requests: {
        total: 0,
        api: 0,
        ui: 0
    }
}

export const onRequest = defineMiddleware(async (context, next) => {
    // Add CORS headers for /api requests
    metrics.requests.total++
    if(context.url.pathname.startsWith("/api")) {
        metrics.requests.api++
        const response = await next();
        console.debug(context.url.origin, context.site?.origin, context.url.origin)
        if(CORS_ALLOW_ANY) {
            response.headers.set("Access-Control-Allow-Origin", "*")
        } else if((context.site && context.url.origin === context.site.origin) || CORS_ALLOW_LIST.includes(context.url.origin)) {
            response.headers.set("Access-Control-Allow-Origin", context.url.origin)
        }
        // Handle any 404 for API so we always try to return JSON
        if(response.status === 404 && context.routePattern === "/404") {
            return new Response(JSON.stringify({
                error: "NOT_FOUND",
                message: "No route found"
            }), { status: response.status, statusText: response.statusText, headers: {...response.headers, "Content-Type": "application/json" }})
        }
        return response
    } else {
        metrics.requests.ui++
    }

    // return a Response or the result of calling `next()`
    return next();
})