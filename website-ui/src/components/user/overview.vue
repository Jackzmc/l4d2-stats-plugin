<template>
<div class="columns">
    <div class="column">
        <h2 class='title is-2'>Stats Overview</h2>
        <h6 class="title is-6" id="playerstats">Player Information</h6>
        <table class="table is-fullwidth is-bordered">
            <tbody>
            <tr>
                <th>SteamID</th>
                <td>
                <p>
                {{user.steamid}}&nbsp;
                <a :href="'https://steamdb.info/calculator/' + communityID">[SteamDB]</a>&nbsp;
                <a :href="'https://steamcommunity.com/profiles/' + communityID">[Steam Community]</a>
                </p>
                </td>
            </tr>
            <tr>
                <th>Creation Date</th>
                <td>{{user.created_date | formatDateAndRel}}</td>
            </tr>
            <tr>
                <th>Last Played</th>
                <td>{{user.last_join_date | formatDateAndRel}}</td>
            </tr>
            <tr>
                <th>Last Location</th>
                <td>{{user.last_location}}</td>
            </tr>
            <tr>
                <th>Connections</th>
                <td>{{user.connections}}</td>
            </tr>
            <tr>
                <th>Time Played</th>
                <td>{{user.minutes_played | formatMinutes}}</td>
            </tr>
            </tbody>
        </table>
        <hr>
        <h6 class="title is-6">Kills</h6>
        <div class="columns">
            <div class="column">
            <table class="table is-fullwidth is-bordered">
                <thead>
                <tr>
                    <th>Class</th>
                    <th align="center">Kills As Survivor</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>Smoker</td>
                    <td class="tvalue">{{user.kills_smoker}}</td>
                </tr>
                <tr>
                    <td>Boomer</td>
                    <td class="tvalue">{{user.kills_boomer}}</td>
                </tr>
                <tr>
                    <td>Hunter</td>
                    <td class="tvalue">{{user.kills_hunter}}</td>
                </tr>
                <tr>
                    <td>Spitter</td>
                    <td class="tvalue">{{user.kills_spitter}}</td>
                </tr>
                <tr>
                    <td>Charger</td>
                    <td class="tvalue">{{user.kills_charger}}</td>
                </tr>

                </tbody>
            </table>
            </div>
            <div class="column">
            <table class="table is-fullwidth is-bordered">
                <thead>
                <tr>
                    <th>Class</th>
                    <th align="center">Kills</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>Tank</td>
                    <td class="tvalue">{{user.tanks_killed}}</td>
                </tr>
                <tr>
                    <td>Tank (Solo)</td>
                    <td class="tvalue">{{user.tanks_killed_solo}}</td>
                </tr>
                <tr>
                    <td>Tank (Melee Only)</td>
                    <td class="tvalue">{{user.tanks_killed_melee}}</td>
                </tr>
                <tr>
                    <td>Witch</td>
                    <td class="tvalue">{{user.kills_witch}}</td>
                </tr>
                <tr>
                    <td>Commons</td>
                    <td class="tvalue">{{user.common_kills}}</td>
                </tr>
                </tbody>
            </table>
            </div>
        </div>
        
        <hr>
        <h6 id="survivorstats" class="title is-6">Survivor Stats</h6>
        <div class="columns">
            <div class="column is-4">
            <p><u>Damage Dealt</u></p>
            <br>
            <table class="table is-bordered is-fullwidth">
                <thead>
                <tr>
                    <th>Type</th>
                    <th align="center">Damage</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>Total Given</td>
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
                </tbody>
            </table>
            </div>
            <div class="column is-4">
            <p><u>Item Uses</u></p>
            <br>
            <table class="table is-bordered is-fullwidth">
                <thead>
                <tr>
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
                    <td>Defibs Used</td>
                    <td class="tvalue">{{user.defibs_used | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Ammo Packs</td>
                    <td class="tvalue">{{user.ammo_packs_used | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Kits (Self)</td>
                    <td class="tvalue">{{user.heal_self | formatNumber}}</td>
                </tr>
                <tr>
                    <td>Kits (Others)</td>
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
                <tr>
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
                </tbody>
            </table>
            </div>
        </div>
        <hr>
        <h5 id="throwables" class="title is-5">Throwable Statistics</h5>
        <table class="table is-bordered is-fullwidth">
            <thead>
            <tr>
                <th>Throwable</th>
                <th align="center">Damage</th>
                <th align="center">Kills</th>
                <th align="center">Thrown</th>
            </tr>
            </thead>
            <tbody>
            <tr>
                <td>Molotov</td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
            </tr>
            <tr>
                <td>Puke</td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
            </tr>
            <tr>
                <td>Pipe</td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
            </tr>
            <tr>
                <td>Gascan</td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
                <td class="tvalue"></td>
            </tr>
            </tbody>
        </table>
        <hr>
        <h5 id="times" class="title is-5">Times</h5>
        <p>This statistic has no data recorded.</p>
    </div>
    <div class="column is-4">
        <div class="box">
            <h5 class="title is-5">Sections</h5>
            <ul>
            <li><a href="#playerinfo">Player Information</a></li>
            <li><a href="#kills">Kills</a></li>
            <li><a href="#survivorstats">Survivor Stats</a></li>
            <li><a href="#throwables">Throwable Stats</a></li>
            <li><a href="#times">Times</a></li>
            </ul>
        </div>
        <div class="box">
            <h5 class="title is-5">Best Map</h5>
            <img :src="mapUrl" />
            <p><strong>Dead Center</strong></p>
            <p>0 Wins</p>
            <p>Fastest Time: 5s</p>
        </div>
    </div>
</div>
</template>

<script>
import {format, formatDuration, formatDistanceToNow} from 'date-fns'
import SteamID from 'steamid'
export default {
    props: ['user'],
    computed: {
        disabled() {
            return this.error || this.not_found
        },
        communityID() {
            return this.user.steamid ? new SteamID(this.user.steamid).getSteamID64() : null
        },
        mapUrl() {
            const chapterid = 1;
            return `https://steamcommunity-a.akamaihd.net/public/images/gamestats/550/c${chapterid}.jpg`
        }
    },
    filters:{
        formatDate(inp) {
            return format(new Date(inp), "yyyy-MM-dd 'at' HH:mm 'UTC'")
        },
        formatDateAndRel(inp) {
            const _date = new Date(inp)
            const date = format(_date, "yyyy-MM-dd 'at' HH:mm 'UTC'");
            const rel = formatDistanceToNow(_date)
            return `${date} (${rel} ago)`
        },
        formatMinutes(min) {
            return formatDuration({minutes: min})
        }
    }
}
</script>

<style scoped>
.tvalue {
  text-align: center;
}
</style>