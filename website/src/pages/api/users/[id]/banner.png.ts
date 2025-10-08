import type { APIRoute } from "astro";
import { getUser, getUserTopStats } from "@/models/User.ts";
import { api404 } from "@/utils/api.ts";
import { Canvas, FontLibrary, Image, loadImage, loadImageData, type CanvasRenderingContext2D } from 'skia-canvas';
import path from "path";
import { formatHumanDuration } from "@/utils/date.ts";
import { Survivor, SURVIVOR_DEFS } from "@/types/game.ts";

const WATERMARK_TEXT = process.env.USER_WATERMARK_TEXT || "stats.jackz.me"

const PUBLIC_ROOT = import.meta.env.PROD ? path.resolve('./dist/client') : path.resolve('./public')
console.debug({ cwd: process.cwd(), dirname: import.meta.dirname, PUBLIC_ROOT, "maybe": path.resolve('./'), "maybe2": path.resolve(path.join(import.meta.dirname, '../../../../assets/'))})

const Futurot = path.join(PUBLIC_ROOT, "fonts/futurot.woff")
FontLibrary.use("futurot", Futurot)

function drawText(ctx: CanvasRenderingContext2D, text: string, x: number, y: number, opts: { font?: string, color?: string, filter?: string } = {}) {
  ctx.save()
  if(opts.filter) ctx.filter = opts.filter
  if(opts.font) ctx.font = opts.font
  if(opts.color) ctx.fillStyle = opts.color

  ctx.fillText(text, x, y)

  ctx.restore()
}

function drawBackgroundImage(ctx: CanvasRenderingContext2D, image: Image, color: [number, number, number, number] = [0,0,0,0.5]) {
  if(color[3] > 1.0) throw new Error("Alpha must be between 0.0 and 1.0")
  ctx.save()
  ctx.filter = "blur(4px) brightness(25%) "
  // ctx.filter = "blur(4px) brightness(80%) contrast(60%)"
  ctx.drawImage(image, 0, 0, ctx.canvas.width, ctx.canvas.height)
  // ctx.fillStyle = `rgba(${color.join(',')})`;
  // ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
  ctx.restore()
}

const DARK_BG_COLOR: [number,number,number,number] = [ 0, 0, 0, 0.75 ]
const LIGHT_BG_COLOR: [number,number,number,number]  = [ 255, 255, 255, 0.6 ]

const MARGIN_PX = 20
const CANVAS_INNER_DIM = [588, 194]

export const BANNER_SIZE = [CANVAS_INNER_DIM[0] + MARGIN_PX, CANVAS_INNER_DIM[1] + MARGIN_PX]

export const GET: APIRoute = async ({ params, request, url }) => {
  if(!params.id) return api404("MISSING_USER_ID", "A user ID is required")

  // Allow overriding survivor type
  let survivorOverride = url.searchParams.has("survivor") ? Number(url.searchParams.get("survivor")) : null
  if(survivorOverride != undefined && (survivorOverride < 0 || survivorOverride > Survivor.Louis)) survivorOverride = null

  const user = await getUser(params.id)
  if(!user) return api404("USER_NOT_FOUND", "No user found")
  const topStats = (await getUserTopStats(params.id))!

  const survivor: Survivor = survivorOverride != null ? survivorOverride : Number(topStats.top_char.value)
  const survivorDef = SURVIVOR_DEFS[survivor]

  const canvas = new Canvas(BANNER_SIZE[0], BANNER_SIZE[1])
  const ctx = canvas.getContext('2d')

  const shouldDrawBg = url.searchParams.get("bg") != "f" && url.searchParams.get("bg") !== "0"

  if(shouldDrawBg) drawBackgroundImage(ctx, 
    await loadImage(path.join(PUBLIC_ROOT, `img/maps/screenshots/${topStats.top_map.id!}.jpeg`)),
    survivorDef.colorIsDark ? LIGHT_BG_COLOR : DARK_BG_COLOR
  )

  const survivorImg = await loadImage(path.join(PUBLIC_ROOT, `img/fullbody/${survivorDef.name.toLowerCase()}.png`))
  const width = survivorImg.width * (CANVAS_INNER_DIM[1] / survivorImg.height)
  // subtract another - 20 to prevent the feet being too far down for some reason
  ctx.drawImage(survivorImg, MARGIN_PX, MARGIN_PX, width - 20, CANVAS_INNER_DIM[1] - 20)

  // if(shouldDrawBg) ctx.fillStyle = survivorDef.colorIsDark ? 'black' : 'white' // default color for all text:
  if(shouldDrawBg) ctx.fillStyle = "white"
  drawText(ctx, user.last_alias, 120+MARGIN_PX, 40+MARGIN_PX, { font: "bold 20pt futurot", color: survivorDef.color, filter: `drop-shadow(0px 0px 1px white)` })

  drawText(ctx, `${topStats.played_any.count.toLocaleString()} games played`, 128+MARGIN_PX, 65+MARGIN_PX, { font: "20px sans-serif" })
  drawText(ctx, `${formatHumanDuration(user.minutes_played, ", ", ["day", "hour", "minute"])} of playtime`, 124+MARGIN_PX, 90+MARGIN_PX, { font: "20px sans-serif" })
  drawText(ctx, `Favorite map: ${topStats.top_map.value}`, 128+MARGIN_PX, 115+MARGIN_PX, { font: "20px sans-serif"})  
  drawText(ctx, `Favorite weapon: ${topStats.top_weapon.value}`, 128+MARGIN_PX, 140+MARGIN_PX, { font: "20px sans-serif"})  

  const playStyle = ""
  drawText(ctx, playStyle, 128+MARGIN_PX, 170+MARGIN_PX, { font: "bold 24px sans-serif MT" })

  ctx.restore()
  ctx.font = 'light 6pt serif'
  ctx.fillStyle = '#737578'

  const waterMarkDim = ctx.measureText(WATERMARK_TEXT)
  ctx.fillText(WATERMARK_TEXT, canvas.width - waterMarkDim.actualBoundingBoxRight - 8 - MARGIN_PX, canvas.height - 8 - MARGIN_PX)

  const buf = await canvas.toBuffer("png")
  return new Response(buf as any, { 
    headers: {
      'Content-Type': 'image/png',
      'Cache-Control': import.meta.env.PROD ? 'public, max-age=86400, s-maxage=172800, stale-while-revalidate=604800, stale-if-error=604800' : 'no-cache'
    }
  })
}

