import type { APIRoute } from "astro";
import { getUser, getUserTopStats } from "@/models/User.ts";
import { api404 } from "@/utils/api.ts";
import { Canvas, FontLibrary, Image, loadImage, type CanvasRenderingContext2D } from 'skia-canvas';
import path from "path";
import { formatHumanDuration } from "@/utils/date.ts";
import { Survivor, SURVIVOR_DEFS } from "@/types/game.ts";

const WATERMARK_TEXT = import.meta.env.USER_WATERMARK_TEXT || process.env.USER_WATERMARK_TEXT

const PUBLIC_ROOT = import.meta.env.PROD ? path.resolve('./dist/client') : path.resolve('./public')

const MARGIN_PX = 20
const CANVAS_INNER_DIM = [1200, 600]


FontLibrary.use("futurot", path.join(PUBLIC_ROOT, "fonts/futurot.woff"))
FontLibrary.use("arial", path.join(PUBLIC_ROOT, "fonts/arial.ttf"))

function drawText(ctx: CanvasRenderingContext2D, text: string, x: number, y: number, opts: { maxWidth?: number, wrap?: boolean, font?: string, color?: string, filter?: string } = {}) {
  ctx.save()
  if(opts.filter) ctx.filter = opts.filter
  if(opts.font) ctx.font = opts.font
  if(opts.color) ctx.fillStyle = opts.color
  if(opts.wrap != undefined) ctx.textWrap = opts.wrap

  ctx.fillText(text, x, y, opts.maxWidth)

  ctx.restore()
}

function drawBackgroundImage(ctx: CanvasRenderingContext2D, image: Image, color: [number, number, number, number] = [0,0,0,0.5]) {
  if(color[3] > 1.0) throw new Error("Alpha must be between 0.0 and 1.0")
  ctx.save()
  ctx.filter = "blur(8px) brightness(45%) "
  // ctx.filter = "blur(4px) brightness(80%) contrast(60%)"
  ctx.drawImage(image, 0, 0, ctx.canvas.width, ctx.canvas.height)
  // ctx.fillStyle = `rgba(${color.join(',')})`;
  // ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
  ctx.restore()
}

function findSmallestFontScale(ctx: CanvasRenderingContext2D, maxSize: number, text: string, maxWidth: number, options: { minSize?: number, fontFamily?: string }= {}): number {
  ctx.save()
  const minSize = options.minSize ?? 0
  let size = Math.round(maxSize)
  while(size > minSize) {
    ctx.font = `${size}pt ${options.fontFamily ?? ""}`
    const width = ctx.measureText(text).width
    if(width <= maxWidth) {
      ctx.restore()
      return size
    }
    size -= 1
  }
  ctx.restore()
  return Math.round(minSize)
}

function getTextSize(ctx: CanvasRenderingContext2D, text: string, font: string): ReturnType<CanvasRenderingContext2D['measureText']> {
  ctx.save()
  ctx.font = font
  const mes = ctx.measureText(text)
  ctx.restore()
  return mes
}

function performCtx(ctx: CanvasRenderingContext2D, cb: (ctx: CanvasRenderingContext2D) => any): any {
  ctx.save()
  const a = cb(ctx)
  ctx.restore()
  return a
}

async function tryGetImage(mapId?: string) {
  try {
    return await loadImage(path.join(PUBLIC_ROOT, `img/maps/screenshots/${mapId || "c1m4_atrium"}.jpeg`))
  } catch(err) {
    console.error(`[Banner] Failed to load image: `, err)
    // fall back to hotel on error 
    return await loadImage(path.join(PUBLIC_ROOT, "img/maps/screenshots/c1m4_atrium.jpeg"))
  }
}

const DARK_BG_COLOR: [number,number,number,number] = [ 0, 0, 0, 0.75 ]
const LIGHT_BG_COLOR: [number,number,number,number]  = [ 255, 255, 255, 0.6 ]
export const BANNER_SIZE = [CANVAS_INNER_DIM[0] + MARGIN_PX, CANVAS_INNER_DIM[1] + MARGIN_PX]

export const GET: APIRoute = async ({ params, request, url }) => {
  if(!params.id) return api404("MISSING_USER_ID", "A user ID is required")
  // Allow overriding survivor type
  let survivorOverride = url.searchParams.has("survivor") ? Number(url.searchParams.get("survivor")) : null
  if(survivorOverride != undefined && (survivorOverride < 0 || survivorOverride > Survivor.Louis)) survivorOverride = null

  const user = await getUser(params.id)
  if(!user) return api404("USER_NOT_FOUND", "No user found")
  const topStats = (await getUserTopStats(params.id))!
  const stats = await getUser(params.id)

  // Use override, if not, check if they have top_char, if not, use bill as default
  const survivor: Survivor = survivorOverride 
    || (topStats.top_char && topStats.top_char.value != "" && Number(topStats.top_char.value)) 
    || 0
  const survivorDef = SURVIVOR_DEFS[survivor]

  const canvas = new Canvas(BANNER_SIZE[0], BANNER_SIZE[1])
  const ctx = canvas.getContext('2d')

  const shouldDrawBg = url.searchParams.get("bg") != "f" && url.searchParams.get("bg") !== "0"

  if(shouldDrawBg) {
    const img = await tryGetImage(topStats.top_map?.id)
    drawBackgroundImage(ctx, 
      // Load map image, where topStats.top_map *should* always be an official map which we have images for
      // If they don't have top map or getting map errors, default to c1m1_hotel
      img,
      survivorDef.colorIsDark ? LIGHT_BG_COLOR : DARK_BG_COLOR
    )
  }
  const survivorImg = await loadImage(path.join(PUBLIC_ROOT, `img/fullbody/${survivorDef.name.toLowerCase()}.png`))
  const width = survivorImg.width * (CANVAS_INNER_DIM[1] / survivorImg.height)
  // subtract another - 20 to prevent the feet being too far down for some reason
  ctx.drawImage(survivorImg, MARGIN_PX, MARGIN_PX, width - 20, CANVAS_INNER_DIM[1] - 20)

  // if(shouldDrawBg) ctx.fillStyle = survivorDef.colorIsDark ? 'black' : 'white' // default color for all text:
  if(shouldDrawBg) ctx.fillStyle = "white"
  //"01234567890123456789012345678901"
  const startPos = [width + 10, MARGIN_PX + 90]
  const maxWidth = CANVAS_INNER_DIM[0] - startPos[0]
  const lineGap = 22
  const statFont = "34px futurot"
  const dim = getTextSize(ctx, "test string", statFont)
  const lineHeight = dim.actualBoundingBoxAscent + dim.actualBoundingBoxDescent + lineGap

  // const size = findSmallestFontScale(ctx, 48, user.last_alias, maxWidth, { fontFamily: "futurot"})
  // console.log("size", size, "maxWidth", maxWidth)
  drawText(ctx, user.last_alias, startPos[0], startPos[1], { wrap: true, font: `bold 50pt futurot`, color: survivorDef.color, filter: `drop-shadow(0px 0px 1px white)`, maxWidth })
  startPos[1] += 100

  drawText(ctx, `${topStats.played_any.count.toLocaleString()} game${topStats.played_any.count > 1 ? 's' : ''} played`, startPos[0], startPos[1], { font: statFont })
  startPos[1] += lineHeight
  const durationText = user.minutes_played > 60 ? formatHumanDuration(user.minutes_played * 60, "", ["day", "hour", "minute"]) : ` < 1 min`
  drawText(ctx, `${durationText} played`, startPos[0] - 10, startPos[1], { font: statFont})
  startPos[1] += lineHeight
  drawText(ctx, `Favorite map: ${topStats.top_map?.value ?? "None"}`, startPos[0], startPos[1], { font: statFont })  
  startPos[1] += lineHeight
  drawText(ctx, `Favorite weapon: ${topStats.top_weapon?.value ?? "None"}`, startPos[0], startPos[1], { font: statFont })  
  startPos[1] += lineHeight
  drawText(ctx, `${stats?.clowns_honked.toLocaleString() ?? 0} clowns honked`, startPos[0], startPos[1], { font: statFont })  
  startPos[1] += lineHeight
  drawText(ctx, `${stats?.kills_common.toLocaleString() ?? 0} zombies killed`, startPos[0], startPos[1], { font: statFont })  
  startPos[1] += lineHeight

  // TODO: calculate best stats (highest number for them )
  // or/and add a 'playstyle' thats more simplistic such as "Pill Popper" if pills best stat

  if(WATERMARK_TEXT != undefined) drawWatermark(ctx, WATERMARK_TEXT)

  const buf = await canvas.toBuffer("png")
  return new Response(buf as any, { 
    headers: {
      'Content-Type': 'image/png',
      'Cache-Control': import.meta.env.PROD ? 'public, max-age=86400, s-maxage=172800, stale-while-revalidate=604800, stale-if-error=604800' : 'no-cache'
    }
  })
}

function drawWatermark(ctx: CanvasRenderingContext2D, text: string) {
  ctx.restore()
  ctx.font = 'light 6pt futurot'
  ctx.fillStyle = '#737578'

  const waterMarkDim = ctx.measureText(text)
  ctx.fillText(text, ctx.canvas.width - waterMarkDim.actualBoundingBoxRight - 8 - MARGIN_PX, ctx.canvas.height - 8 - MARGIN_PX)
}