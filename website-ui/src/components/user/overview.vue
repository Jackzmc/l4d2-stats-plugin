<template>
<div class="columns">
    <div class="column">
        <h2 class='title is-2'>Stats Overview</h2>
        <img :src="imageBannerUrl" onerror="this.style.display='none'" />
        <linkanchor id="playerstats" text="Player Information" />
        <table class="table is-fullwidth is-bordered">
            <tbody>
            <tr>
                <th>SteamID</th>
                <td colspan="3"><p>
                    {{user.steamid}}&nbsp;
                    <span class="is-pulled-right buttons">
                    <b-button tag="a" size="is-small" type="is-info" :href="'https://steamdb.info/calculator/' + communityID">SteamDB</b-button>
                    <b-button tag="a" size="is-small" type="is-info" :href="'https://steamcommunity.com/profiles/' + communityID">Community Profile</b-button>
                    </span>
                </p></td>
            </tr>
            <tr>
                <th>First Played</th>
                <td colspan="3" v-html="formatDateAndRel(user.created_date*1000)"></td>
            </tr>
            <tr>
                <th>Last Played</th>
                <td colspan="3" v-html="formatDateAndRel(user.last_join_date*1000)"></td>
            </tr>
            <tr>
                <th>Last Location</th>
                <td colspan="3" >{{user.country}}</td>
            </tr>
            <tr>
                <th>Connections</th>
                <td style="color: blue">{{user.connections | formatNumber}}</td>
                <th>Total Time Played</th>
                <td style="color: blue">{{ humanReadable(user.minutes_played)}}</td>
            </tr>
            <tr>
                <td><b>Play Style</b> <em class="is-pulled-right is-inline">(in alpha)</em></td>
                <td v-if="playstyle.error">
                    <b-tooltip type="is-danger" class="has-text-danger" :label="playstyle.error">Failed to fetch</b-tooltip>
                </td>
                <td v-else-if="playstyle.data">{{ playstyle.data }}</td>
                <td v-else>Loading...</td>
                <td><b>
                    <b-tooltip label="The calculated rating based off admin notes on the player">
                        Rating
                    </b-tooltip>
                </b></td>
                <td v-if="playrating.error">
                    <b-tooltip type="is-danger" class="has-text-danger" :label="playrating.error">Failed to fetch</b-tooltip>
                </td>
                <td v-else-if="playrating.data && playrating.data.key">
                    {{ playrating.data.key }}
                    <b-tooltip v-if="playrating.data.value != null">
                        ({{playrating.data.value}})
                        <template v-slot:content>
                            The rating value of this player.<br />
                            <span class="has-text-success">Positive = better</span>
                        </template>
                    </b-tooltip>
                </td>
                <td v-else-if="playrating.data">
                    <em>No rating</em>
                </td>
                <td v-else>Loading...</td>
            </tr>
            </tbody>
        </table>
        <hr>
        <linkanchor id="kills" text="Kills" />
        <div class="columns">
            <div class="column">
            <table class="table is-fullwidth is-bordered">
                <thead>
                <tr class="has-background-white-ter">
                    <th>Class</th>
                    <th align="center">Kills</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>Smoker</td>
                    <td class="tvalue">{{user.kills_smoker | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Boomer</td>
                    <td class="tvalue">{{user.kills_boomer | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Hunter</td>
                    <td class="tvalue">{{user.kills_hunter | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Spitter</td>
                    <td class="tvalue">{{user.kills_spitter | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Charger</td>
                    <td class="tvalue">{{user.kills_charger | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Jockey</td>
                    <td class="tvalue">{{user.kills_jockey | formatNumber}}</td>
                </tr>
                </tbody>
            </table>
            </div>
            <div class="column">
            <table class="table is-fullwidth is-bordered">
                <thead>
                <tr class="has-background-white-ter">
                    <th>Class</th>
                    <th align="center">Kills</th>
                </tr>
                </thead>
                <tbody>
                  <tr>
                      <td>Commons</td>
                      <td class="tvalue">{{user.common_kills | formatNumber}}</td>
                  </tr>
                  <tr>
                      <td>With Minigun</td>
                      <td class="tvalue">{{user.kills_minigun | formatNumber}}</td>
                  </tr>
                  <tr>
                      <td>Teammates</td>
                      <td class="tvalue">{{user.ff_kills | formatNumber}}</td>
                  </tr>
                  <tr>
                      <td>Tank</td>
                      <td class="tvalue">{{user.tanks_killed | formatNumber}}</td>
                  </tr>
                  <tr>
                      <td>Tank (Solo)</td>
                      <td class="tvalue">{{user.tanks_killed_solo | formatNumber}}</td>
                  </tr>
                  <tr>
                      <td>Witch</td>
                      <td class="tvalue">{{user.kills_witch | formatNumber}}</td>
                  </tr>

                </tbody>
            </table>
            </div>
        </div>

        <hr>
        <linkanchor id="survivorstats" text="Survivor Statistics" />
        <div class="columns">
            <div class="column is-4">
            <p><u>Damages</u></p>
            <br>
            <table class="table is-bordered is-fullwidth">
                <thead>
                <tr class="has-background-white-ter">
                    <th>Type</th>
                    <th align="center">Damage</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>Total Dealt</td>
                    <td class="tvalue">{{user.survivor_damage_give | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Total Received</td>
                    <td class="tvalue">{{user.survivor_damage_rec | formatNumber}}</td>
                </tr>
                <tr>
                    <td>To Tank</td>
                    <td class="tvalue">{{user.damage_to_tank | formatNumber}}</td>
                </tr>
                <tr>
                    <td>To Witch</td>
                    <td class="tvalue">{{user.damage_witch | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Friendly Fire</td>
                    <td class="tvalue">{{user.survivor_ff | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Friendly Fire Received</td>
                    <td class="tvalue">{{user.survivor_ff_recv | formatNumber}}</td>
                </tr>
                <tr>
                    <td>With Melee</td>
                    <td class="tvalue">{{user.melee_kills | formatNumber}}</td>
                </tr>
                </tbody>
            </table>
            </div>
            <div class="column is-4">
            <p><u>Item Usage</u></p>
            <br>
            <table class="table is-bordered is-fullwidth">
                <thead>
                <tr class="has-background-white-ter">
                    <th>Item</th>
                    <th align="center">Uses</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>Pills</td>
                    <td class="tvalue">{{user.pills_used | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Adrenaline</td>
                    <td class="tvalue">{{user.adrenaline_used | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Defibs</td>
                    <td class="tvalue">{{user.defibs_used | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Ammo Packs</td>
                    <td class="tvalue">{{user.packs_used | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Kits <em>(Self)</em></td>
                    <td class="tvalue">{{user.heal_self | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Kits <em>(Others)</em></td>
                    <td class="tvalue">{{user.heal_others | formatNumber}}</td>
                </tr>
                </tbody>
            </table>
            </div>
            <div class="column is-4">
            <p><u>Misc</u></p>
            <br>
            <table class="table is-bordered is-fullwidth">
                <thead>
                <tr class="has-background-white-ter">
                    <th>Stat</th>
                    <th align="center">Value</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>Incaps</td>
                    <td class="tvalue">{{user.survivor_incaps | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Deaths</td>
                    <td class="tvalue">{{user.survivor_deaths | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Doors Opened</td>
                    <td class="tvalue">{{user.door_opens | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Finales Won</td>
                    <td class="tvalue">{{user.finales_won | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Times Revived</td>
                    <td class="tvalue">{{user.revived | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Revived Others</td>
                    <td class="tvalue">{{user.revived_others | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Clowns Honked</td>
                    <td class="tvalue">{{user.clowns_honked | formatNumber}}</td>
                </tr>
                <tr>
                  <td>Boomed others</td>
                  <td class="tvalue">{{ user.boomer_mellos | formatNumber }}</td>
                </tr>
                <tr>
                  <td>Boomed self</td>
                  <td class="tvalue">{{ user.boomer_mellos_self | formatNumber }}</td>
                </tr>
                </tbody>
            </table>
            </div>
        </div>
        <hr>
        <linkanchor id="skills" text="Skills" />
        <table class="table is-bordered is-fullwidth">
            <thead>
            <tr class="has-background-white-ter">
                <th>Skill</th>
                <th align="center">Count</th>
            </tr>
            </thead>
            <tbody>
            <tr>
                <td>Witches Crowned</td>
                <td class="tvalue">{{user.witches_crowned | formatNumber}}</td>
            </tr>
            <tr>
                <td>Smokers Self-cleared</td>
                <td class="tvalue">{{user.smokers_selfcleared | formatNumber}}</td>
            </tr>
            <tr>
                <td>Hunters Deadstopped</td>
                <td class="tvalue">{{user.hunters_deadstopped | formatNumber}}</td>
            </tr>
            <tr>
                <td>Times helped pinned teammate</td>
                <td class="tvalue">{{user.cleared_pinned | formatNumber}}</td>
            </tr>
            <tr>
                <td>Times hit by tank rock</td>
                <td class="tvalue">{{user.rocks_hitby | formatNumber}}</td>
            </tr>
            </tbody>
        </table>
        <hr>
        <linkanchor id="throwables" text="Throwable Statistics" />
        <table class="table is-bordered is-fullwidth">
            <thead>
            <tr class="has-background-white-ter">
                <th>Throwable</th>
                <th align="center">Damage</th>
                <th align="center">Kills</th>
                <th align="center">Thrown</th>
            </tr>
            </thead>
            <tbody>
            <tr>
                <td>Molotov</td>
                <td class="tvalue">{{user.damage_molotov | formatNumber}}</td>
                <td class="tvalue">{{user.kills_molotov | formatNumber}}</td>
                <td class="tvalue">{{user.throws_molotov  | formatNumber}}</td>
            </tr>
            <tr>
                <td>Puke</td>
                <td class="has-text-centered">-</td>
                <td class="tvalue">-</td>
                <td class="tvalue">{{user.throws_puke | formatNumber}}</td>
            </tr>
            <tr>
                <td>Pipe</td>
                <td class="has-text-centered">-</td>
                <td class="tvalue">{{user.kills_pipe | formatNumber}}</td>
                <td class="tvalue">{{user.throws_pipe | formatNumber}}</td>
            </tr>
            </tbody>
        </table>
        <hr>
        <linkanchor id="averages" text="Averages" />
        <p v-if="!averages">This statistic has no data recorded.</p>
        <table v-else class="table is-bordered is-fullwidth">
            <thead>
            <tr class="has-background-white-ter">
                <th>Statistic</th>
                <th align="center">Total</th>
                <th align="center">Per Session</th>
                <th align="center">Per Hour Played</th>
                <th align="center">Per {{averages.globalTotalSessions | formatNumber}} sessions</th>
            </tr>
            </thead>
            <tbody>
            <tr>
                <td>Deaths</td>
                <td class="tvalue">{{averages.survivor_deaths | formatNumber}}</td>
                <td class="tvalue">{{(averages.survivor_deaths / averages.totalSessions).toFixed(2)}}</td>
                <td class="tvalue">{{(averages.survivor_deaths / hoursPlayed).toFixed(5)}}</td>
                <td class="tvalue">{{(averages.survivor_deaths / averages.globalTotalSessions).toFixed(2)}}</td>
            </tr>
            <tr>
                <td>Friendly Fire</td>
                <td class="tvalue">{{averages.survivor_ff | formatNumber}}</td>
                <td class="tvalue">{{(averages.survivor_ff / averages.totalSessions).toFixed(2)}}</td>
                <td class="tvalue">{{(averages.survivor_ff / averages.minutes_played).toFixed(5)}}</td>
                <td class="tvalue">{{(averages.survivor_ff / averages.globalTotalSessions).toFixed(2)}}</td>
            </tr>
            <tr>
                <td>Healing Others</td>
                <td class="tvalue">{{averages.heal_others | formatNumber}}</td>
                <td class="tvalue">{{(averages.heal_others / averages.totalSessions).toFixed(2)}}</td>
                <td class="tvalue">{{(averages.heal_others / hoursPlayed).toFixed(5)}}</td>
                <td class="tvalue">{{(averages.heal_others / averages.globalTotalSessions).toFixed(2)}}</td>
            </tr>
            <tr>
                <td>Revived Others</td>
                <td class="tvalue">{{averages.revived_others | formatNumber}}</td>
                <td class="tvalue">{{(averages.revived_others / averages.totalSessions).toFixed(2)}}</td>
                <td class="tvalue">{{(averages.revived_others / hoursPlayed).toFixed(5)}}</td>
                <td class="tvalue">{{(averages.revived_others / averages.globalTotalSessions).toFixed(2)}}</td>
            </tr>
            <tr>
                <td>Incaps</td>
                <td class="tvalue">{{averages.survivor_incaps | formatNumber}}</td>
                <td class="tvalue">{{(averages.survivor_incaps / averages.totalSessions).toFixed(2)}}</td>
                <td class="tvalue">{{(averages.survivor_incaps / hoursPlayed).toFixed(5)}}</td>
                <td class="tvalue">{{(averages.survivor_incaps / averages.globalTotalSessions).toFixed(2)}}</td>
            </tr>
            <tr>
                <td>Minutes Spent Idle</td>
                <td class="tvalue">{{averages.minutes_idle | formatNumber}}</td>
                <td class="tvalue">{{(averages.minutes_idle / averages.totalSessions).toFixed(2)}}</td>
                <td class="tvalue">{{(averages.minutes_idle / hoursPlayed).toFixed(5)}}</td>
                <td class="tvalue">{{(averages.minutes_idle / averages.globalTotalSessions).toFixed(2)}}</td>
            </tr>
            </tbody>
        </table>
    </div>
    <!-- TODO: Add like a custom image generation -->
    <div class="column is-3">
        <div class="box">
            <h5 class="title is-5">Sections</h5>
            <div class="content has-text-left">
                <ul>
                <li><a href="#playerinfo">Player Information</a></li>
                <li><a href="#kills">Kills</a></li>
                <li><a href="#survivorstats">Survivor Stats</a></li>
                <li><a href="#skills">Skills</a></li>
                <li><a href="#throwables">Throwable Stats</a></li>
                <li><a href="#averages">Averages</a></li>
                </ul>
            </div>
        </div>
        <span v-if="topStats">
        <div class="box has-background-info has-text-white" style="height: 170px" v-if="topStats.topCharacter">
          <div class="columns">
            <div class="column is-6">
              <img class="is-pulled-left image is-128x128" :src="'/img/portraits/' + getModelName(topStats.topCharacter.k) + '.png'" />
            </div>
            <div class="column">
              <h4 class="title is-4 has-text-white">Top Played Character</h4>
              <h4 class="subtitle is-4 has-text-centered has-text-white">{{getCharacterName(topStats.topCharacter.k)}}</h4>
              <p class="subtitle is-6 has-text-centered has-text-white">{{topStats.topCharacter.count}} times played</p>
            </div>
          </div>
        </div>
        <div class="box has-text-centered has-background-info has-text-white" v-if="topStats.topMap">
          <h4 class="title is-4 has-text-white">Most Played Map</h4>
          <h4 class="subtitle is-4 has-text-white">{{mostPlayedMapTitle}}</h4>
          <p class="subtitle is-6 has-text-centered has-text-white">{{topStats.topMap.count}} times played</p>
          <hr>
          <div class="columns">
            <div class="column">
              <p><b>{{topStats.mapsPlayed.official}}</b> official maps played</p>
              <p><b>{{topStats.mapsPlayed.custom}}</b> custom maps played</p>
            </div>
            <div class="column is-3">
              <p>{{topStats.mapsPlayed.percentageOfficial}}% Official</p>
            </div>
          </div>
        </div>
        <div class="box has-text-centered has-background-info" v-if="topStats.topWeapon">
          <h4 class="title is-4 has-text-white">Most Used Weapon</h4>
          <h4 class="subtitle is-4 has-text-white">{{topStats.topWeapon}}</h4>
        </div>
        <div class="box has-text-centered has-background-info has-text-white" v-if="topStats.bestSessionByTime">
          <h4 class="title is-4 has-text-white">Best Session Time</h4>
          <h4 class="subtitle is-4">
            <router-link class="has-text-success button" :to="'/sessions/details/' + topStats.bestSessionByTime.id">{{secondsToHms(topStats.bestSessionByTime.difference)}}</router-link>
          </h4>
          <p>{{$options.getMapName(topStats.bestSessionByTime.map)}}</p>
          <p>{{getGamemode(topStats.bestSessionByTime.gamemode)}} • {{getDifficulty(topStats.bestSessionByTime.difficulty)}}</p>
        </div>
        </span>
        <!-- <div class="box">
            <h5 class="title is-5">Best Map</h5>
            <img :src="mapUrl" />
            <p><strong>Dead Center</strong></p>
            <p>0 Wins</p>
            <p>Fastest Time: 5s</p>
        </div> -->
    </div>
    <br>
</div>
</template>

<script>
import {formatDistanceToNow} from 'date-fns'
import SteamID from 'steamid'
import NoMapImage from '@/assets/no_map_image.png'
import linkanchor from '@/components/linkanchor'

import { getMapName } from '@/js/map'

export default {
    metaInfo() {
      return {
        title: "Overview"
      }
    },
    getMapName,
    props: ['user'],
    data() {
        return {
            averages: null,
            topStats: null,
            playstyle: { data: null, error: null },
            playrating: { data: null, error: null }
        }
    },
    computed: {
        imageBannerUrl() {
          return this.user.steamid ? `/api/user/${this.user.steamid}/image` : ''
        },
        disabled() {
            return this.error || this.not_found
        },
        communityID() {
            return this.user.steamid ? new SteamID(this.user.steamid).getSteamID64() : null
        },
        mapUrl() {
            if(this.selected) {
                const official_map = this.selected.map_name && /(c\dm\d_)(.*)/.test(this.selected.map_name);
                if(official_map) {
                    const chapter = parseInt(this.selected.map_name.substring(1,3).replace('m',''))
                    if(chapter <= 6) return `https://steamcommunity-a.akamaihd.net/public/images/gamestats/550/c${chapter}.jpg`
                }
            }
            return NoMapImage
        },
        mostPlayedMapTitle() {
          return getMapName(this.topStats?.topMap.id)
        },
        hoursPlayed() {
          return this.averages?.minutes_played / 60
        }
    },
    watch: {
        '$route.params.user': function() {
            this.fetchAverages()
            .then(() => this.fetchTopStats())
        }
    },
    methods: {
        getModelName(number) {
            switch(number) {
                case 0: return "gambler";
                case 1: return "producer"
                case 2: return "mechanic"
                case 3: return "coach"
                case 4: return "namvet"
                case 5: return "teenangst"
                case 6: return "biker"
                case 7: return "manager"
                default: return "random"
            }
        },
        getCharacterName(number) {
            switch(number) {
                case 0: return "Nick";
                case 1: return "Rochelle"
                case 2: return "Ellis"
                case 3: return "Coach"
                case 4: return "Bill"
                case 5: return "Zoey"
                case 6: return "Francis"
                case 7: return "Louis"
                default: return ""
            }
        },
        secondsToHms(d) {
            d = Number(d);
            const h = Math.floor(d / 3600);
            const m = Math.floor(d % 3600 / 60);
            //const s = Math.floor(d % 3600 % 60);

            const hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
            const mDisplay = m > 0 ? m + (m == 1 ? " minute " : " minutes ") : "";
            //const sDisplay = s > 0 ? s + (s == 1 ? " second" : " seconds") : "";
            return hDisplay + mDisplay;
        },
        formatDateAndRel(inp) {
            if(inp <= 0 || isNaN(inp)) return ""
            try {
                const date = new Date(inp).toLocaleString()
                const rel = formatDistanceToNow(new Date(inp))
                return `${date} <em class='is-pulled-right'>(${rel} ago)</em>`
            }catch(err) {
                return "???"
            }
        },
        humanReadable(minutes) {
            let hours = Math.floor(minutes / 60);
            const days = Math.floor(hours / 24);
            minutes = minutes % 60;
            const day_text = days == 1 ? 'day' : 'days'
            const min_text = minutes == 1 ? 'minute' : 'minutes'
            const hour_text = hours == 1 ? 'hour' : 'hours'
            if(days >= 1) {
                hours = hours % 24;
                return `${days} ${day_text}, ${hours} ${hour_text}`
            }else if(hours >= 1) {
                return `${hours} ${hour_text}, ${minutes} ${min_text}`
            }else{
                return `${minutes} ${min_text}`
            }
        },
        fetchAverages() {
            return this.$http.get(`/api/user/${this.user.steamid}/averages`)
            .then(res => {
                this.averages = res.data;
            })
            .catch(err => {
                console.error('Could not load average values', err)
            })
        },
        fetchPlaystyle() {
            this.playstyle.data = null
            this.playstyle.error = null
            this.$http.get(`https://jackz.me/l4d2/scripts/analyze.php?steamid=${this.user.steamid}&concise=1`)
            .then(res => {
                if(res.data.result)
                  return this.playstyle.data = `${res.data.result.name} (${Math.round(res.data.result.value * 10000) / 10000})`
                switch(res.data.code) {
                  case "NO_DATA":
                    this.playstyle.data = "Not enough data"
                    break
                  case "NO_SESSION_DATA":
                    this.playstyle.data = "No sessions have been played"
                    break
                  default:
                    this.playstyle.data = res.data.code
                }
            })
            .catch(err => {
                console.error('Could not get playstyle: ', err)
                this.playstyle.error = err.message
            })
        },
        fetchPlayrating() {
            this.playrating.data = null
            this.playrating.error = null
            const url = process.env.NODE_ENV === "production"
                ? "https://admin.jackz.me/api/analyze/"
                : "http://localhost:8081/api/analyze/"
            this.$http.get(`${url}${this.user.steamid}`)
            .then(res => {
                this.playrating.data = res.data.rating
            })
            .catch(err => {
                console.error('Could not get playrating: ', err)
                if(err.request.status)
                    this.playrating.data = { key: null }
                else
                    this.playrating.error = err.message
            })
        },
        fetchTopStats() {
            return this.$http.get(`/api/user/${this.user.steamid}/top`)
            .then(res => {
                this.topStats = res.data
            })
            .catch(() => {})
        },
        getDifficulty(inp) {
            switch(inp) {
                case 0: return "Easy"
                case 1: return "Normal"
                case 2: return "Advanced"
                case 3: return "Expert"
            }
        },
        getGamemode(inp) {
            switch(inp) {
                case "coop": return "Campaign"
                case "tankrun": return "TankRun"
                case "rocketdude": return "RocketDude"
                default: {
                    return inp[0].toUpperCase() + inp.slice(1)
                }
            }
        },
    },
    mounted() {
        document.addEventListener("scroll", () => {
            if (document.documentElement.scrollTop > 1000 && this.averages === null) {
                this.averages = false;
                this.fetchAverages();
            }
        })
        if(this.topStats == null) {
          this.fetchTopStats();
        }
        Promise.all([
            this.fetchPlaystyle(),
            this.fetchPlayrating()
        ])

    },
    destroyed() {
        document.removeEventListener('scroll')
    },
    components: {
        linkanchor
    }
}
</script>

<style scoped>
.tvalue {
  text-align: center;
  color: blue;
}
</style>
