import { formatDuration, intervalToDuration, type FormatDurationOptions } from "date-fns"

/**
 * Formats a unix timestamp
 * @param timestamp number of seconds since unix epoch
 * @param onlyDate if false, time will be included such as [at hh:mm]
 * @returns yyyy-mm-dd if onlyDate or yyyy-mm-dd at hh:mm
 */
export function formatUnixDate(timestamp?: number, onlyDate = false) {
  const d = timestamp ? new Date(timestamp * 1000) : new Date();
  let output = d.toISOString().split('T')[0]
  if(!onlyDate) output += " at " + d.toLocaleTimeString(undefined, {
    timeStyle: "short"
  });
  return output
}

/**
 * Returns the relative time that has passed from a unix timestamp
 * @param timestamp number of seconds since unix epoch
 * @returns "just now" or "N seconds ago" or "N minutes ago" ... up to "weeks ago"
 */
export function formatRelUnixDate(timestamp: number) : string {
  const date = timestamp ? new Date(timestamp * 1000) : new Date();
  const secondsDiff = ((Date.now() - date.getTime()) / 1000);
  const dayDiff = Math.floor(secondsDiff / 86400);
  const monthsDiff = Math.round(dayDiff / 30)
  const yearsDiff = Math.round(monthsDiff / 12)
  if(yearsDiff > 0) return `${yearsDiff} year${yearsDiff == 1 ? "" : "s"} ago`
  if(monthsDiff > 0) return `${monthsDiff} month${monthsDiff == 1 ? "" : "s"} ago`
  if (isNaN(dayDiff) || dayDiff < 0 || dayDiff >= 31) return "<invalid date>"

  return dayDiff == 0 && (
    secondsDiff < 0 && "just now" || secondsDiff < 60 && `${Math.ceil(secondsDiff)} seconds ago` || secondsDiff < 120 && "1 minute ago" || secondsDiff < 3600 && Math.floor(secondsDiff / 60) + " minutes ago" || secondsDiff < 7200 && "1 hour ago" || secondsDiff < 86400 && Math.floor(secondsDiff / 3600) + " hours ago") || dayDiff == 1 && "yesterday" || dayDiff < 7 && dayDiff + " days ago" || dayDiff < 31 && Math.ceil(dayDiff / 7) + " weeks ago"
    || "Unknown"
}

/**
 * Returns a string representing the duration of a timestamp, of each component of time (months, days, hours, ...)
 * @param timestamp number of seconds since unix epoch
 * @returns 55 years 8 months 29 days 18 hours 44 minutes 12 seconds
 */
export function unixDateToDuration(timestamp: number, formatOptions?: FormatDurationOptions) {
  const date = timestamp ? new Date(timestamp * 1000) : new Date();
  const duration = intervalToDuration({
    start: date,
    end: new Date()
  })
  return formatDuration(duration, formatOptions)
}