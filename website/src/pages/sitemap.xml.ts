const PAGES = [
    "/",
    "/find-games",
    "/recent-games",
    "/summary",
    "/maps",
    "/leaderboards",
]

import type { APIRoute } from "astro";


export const GET: APIRoute = async ({ params, request, site }) => {
    if(!site) return new Response(null, { status: 404 })
    const urlTags = PAGES.map(url => {
        return `<url>\n\t\t<loc>${site!.origin}${url}</loc>\n\t</url>`
    })
    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    ${urlTags.join("\n\t")}
</urlset> `
    return new Response(xml, { 
        headers: {
            'Content-Type': 'application/xml',
            'Cache-Control': import.meta.env.PROD ? 'public, max-age=86400, s-maxage=172800, stale-while-revalidate=604800, stale-if-error=604800' : 'no-cache'
        }
    })
}