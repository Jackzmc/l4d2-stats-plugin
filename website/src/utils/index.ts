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

import type { AstroGlobal, AstroInstance } from 'astro';
import DefaultMapImage from '../assets/maps/posters/default.png'
import { GAMEMODES, Survivor, SURVIVOR_DEFS } from '../types/game.ts';
export function getMapPoster(mapId: string): any {
  return IMAGE_MAP[mapId] ? import(`../assets/maps/posters/official/${IMAGE_MAP[mapId]}.jpeg`) : DefaultMapImage
}
export function getMapScreenshot(mapId: string): any {
  return IMAGE_MAP[mapId] ? import(`../assets/maps/screenshots/${IMAGE_MAP[mapId]}.jpeg`) : DefaultMapImage
}

export function getPortrait(survivorType: Survivor): any {
  return SURVIVOR_DEFS[survivorType] ? import(`../assets/portraits/${SURVIVOR_DEFS[survivorType].model}.png`) : DefaultMapImage
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