import { defineMiddleware } from "astro:middleware";

const CORS_ALLOW_LIST = process.env.API_ALLOWED_ORIGINS ? process.env.API_ALLOWED_ORIGINS.split("") : [""]
const CORS_ALLOW_ANY = CORS_ALLOW_LIST[0] === "*"

export const onRequest = defineMiddleware(async (context, next) => {
    // Add CORS headers for /api requests
    if(context.url.pathname.startsWith("/api")) {
        const response = await next();
        if(CORS_ALLOW_ANY) {
            response.headers.set("Access-Control-Allow-Origin", "*")
        } else if(context.url.origin === context.site?.origin || CORS_ALLOW_LIST.includes(context.url.origin)) {
            response.headers.set("Access-Control-Allow-Origin", context.url.origin)
        }
        return response
    }

    // return a Response or the result of calling `next()`
    return next();
})