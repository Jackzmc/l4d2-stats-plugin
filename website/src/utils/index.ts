export function formatSize(bytes: number, si = false, dp = 1) {
  const thresh = si ? 1000 : 1024;

  if (Math.abs(bytes) < thresh) {
    return bytes + ' B';
  }

  const units = si
    ? ['kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    : ['KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
  let u = -1;
  const r = 10**dp;

  do {
    bytes /= thresh;
    ++u;
  } while (Math.round(Math.abs(bytes) * r) / r >= thresh && u < units.length - 1);

  return (dp > 0 ? bytes.toFixed(dp) : Math.round(bytes)) + ' ' + units[u];
}


export const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export const IMAGE_MAP: Record<string, string> = Object.fromEntries(Object.entries({
    "c1m4_atrium": "c1_dead_center",
    "c2m5_concert": "c2_dark_carnival",
    "c3m4_plantation": "c3_swamp_fever",
    "c4m5_milltown_escape": "c4_hard_rain",
    "c5m5_bridge": "c5_the_parish",
    "c6m3_port": "c6_the_passing",
    "c7m3_port": "c7_the_sacrifice",
    "c8m5_rooftop": "c8_no_mercy",
    "c9m2_lots": "c9_crash_course",
    "c10m5_houseboat": "c10_death_toll",
    "c11m5_runway": "c11_dead_air",
    "c12m5_cornfield": "c12_blood_harvest",
    "c13m4_cutthroatcreek": "c13_cold_stream",
    "c14m2_lighthouse": "c14_last_stand",
}));
type ImageMap = Record<string, { image: () => Promise<{ default: ImageProperties }>, path: string}>
type ImageProperties = {
  src: string,
  width: number,
  height: number,
  format: string
}

export const MAP_POSTERS: ImageMap = Object.fromEntries(Object.entries(import.meta.glob('@/assets/maps/posters/*.{png,jpg,jpeg,webp}'))
  .map(([key, value]) => {
    const mapId = key.split("/").pop()!.split(".").shift()
    return [mapId, {
      image: value,
      path: key
    }]
  }))
export const SURVIVOR_PORTRAITS: ImageMap = Object.fromEntries(Object.entries(import.meta.glob('@/assets/portraits/*.{png,jpg,jpeg,webp}'))
  .map(([key, value]) => {
    const mapId = key.split("/").pop()!.split(".").shift()
    return [mapId, {
      image: value,
      path: key
    }]
  }))
export const WEAPON_IMAGES: ImageMap = Object.fromEntries(Object.entries(import.meta.glob('@/assets/weapons/*.{png,jpg,jpeg,webp}'))
  .map(([key, value]) => {
    const mapId = key.split("/").pop()!.split(".").shift()
    return [mapId, {
      image: value,
      path: key
    }]
  }))


import type { AstroGlobal } from 'astro';
import DefaultMapImage from '@assets/maps/default.png'
import { GAMEMODES, Survivor, SURVIVOR_DEFS } from '@/types/game.ts';
export async function getMapPoster(mapId: string): Promise<ImageProperties> {
  if(MAP_POSTERS[mapId] === undefined) {
    console.warn("No map poster for", mapId)
    return DefaultMapImage
  }
  return (await (MAP_POSTERS[mapId].image())).default
}
export async function getPortrait(survivorType: Survivor): Promise<ImageProperties> {
  return (await (SURVIVOR_PORTRAITS[SURVIVOR_DEFS[survivorType].model].image())).default
}

export async function getWeaponImage(weaponId: string): Promise<ImageProperties | null> {
  if(!WEAPON_IMAGES[weaponId]) throw new Error("Missing weapon image: " + weaponId)
  return (await (WEAPON_IMAGES[weaponId].image())).default
}

export function getGamemode(gamemode: string) {
  let val = GAMEMODES[gamemode]
  if(val) return val
  return val.charAt(0).toUpperCase() + val.slice(1)
}

export function requireParam<T>(params: URLSearchParams, key: string, validValues: string[]): T {
  const value = params.get(key)
  if(value && validValues.includes(value)) {
    return value as T
  } else {
    throw new Error(`Provided parameter "${key}" must have value be one of ${validValues}`)
  }
}

const ROUTE_PATTERN_REGEX = new RegExp(/\[([a-zA-Z0-9-_]+)\]*/g)

/**
 * Replace the parameters of current route. If a param is not defined, falls back to Astro.params or shows raw parameter if none
 * @param astro the astro instance
 * @param params params to override Astro.params with
 * @returns new href
 */
export function replaceRoute(astro: AstroGlobal, params: Record<string, string | number>) {
  let pattern = astro.routePattern
  const match = astro.routePattern.matchAll(ROUTE_PATTERN_REGEX)
  for(const [raw,param] of match) {
    const value: string|number = params[param] || astro.params[param] || raw
    pattern = pattern.replace(`[${param}]`, value.toString())
  }
  return pattern
}