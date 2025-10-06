import type { APIRoute } from "astro";
import { getUser } from "@/models/User.ts";
import { api404 } from "@/utils/api.ts";
import { Canvas, FontLibrary, loadImage } from 'skia-canvas';
import path from "path";
// import { Canvas, loadImage, registerFont } from "canvas";

const WATERMARK_TEXT = "stats.jackz.me"
const ROOT = path.join(import.meta.dirname, "@/")

FontLibrary.use("futurot", path.join(ROOT, "public/fonts/futurot.woff"))

export const GET: APIRoute = async ({ params, request }) => {
  if(!params.id) return api404("MISSING_USER_ID", "A user ID is required")
  const user = await getUser(params.id)
  if(!user) return api404("USER_NOT_FOUND", "No user found")

  const canvas = new Canvas(588, 194)
  const ctx = canvas.getContext('2d')
  // if(req.query.gradient !== undefined) {
  //     const bannerBase = await Canvas.loadImage(`assets/banner-base.png`)
  //     ctx.drawImage(bannerBase, 0, 0, canvas.width, canvas.height)
  // }
  const survivorImg = await loadImage(path.join(ROOT, `src/assets/fullbody/zoey.png`))
  ctx.drawImage(survivorImg, 0, 0, 120, 194)
  ctx.save()
  ctx.font = 'bold 20pt futurot'
  ctx.fillStyle = '#ac0a4dff'
  ctx.fillText(user.last_alias, 130, 40)

  // setLine(ctx, 'Top Weapon: ', top.weapon.name || top.weapon.id, 120, 90)
  // setLine(ctx, 'Top Map: ', top.map.name || top.map.id, 120, 111)
  // ctx.fillText(`${maps.total.toLocaleString()} Games Played (${Math.round(maps.official/maps.total*100)}% official)`, 120, 132)
  // ctx.fillText(`${stats.witchesCrowned.toLocaleString()} witches crowned`, 120, 153)
  // ctx.fillText(`${stats.clownsHonked.toLocaleString()} clowns honked`, 120, 174)
  ctx.restore()
  ctx.font = 'light 6pt serif'
  ctx.fillStyle = '#737578'

  const waterMarkDim = ctx.measureText(WATERMARK_TEXT)
  ctx.fillText(WATERMARK_TEXT, canvas.width - waterMarkDim.actualBoundingBoxRight - 8, canvas.height - 8)

  const buf = await canvas.toBuffer("png")
  return new Response(buf as any, { 
    headers: {
      'Content-Type': 'image/png'
    }
  })
}

