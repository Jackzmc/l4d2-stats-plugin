<template>
  <div class="aboutis-fluid">
    <section class="hero is-info">
      <!-- Hero head: will stick at the top -->

      <!-- Hero content: will be in the middle -->
      <div v-cloak class="hero-body">
        <div class="container has-text-centered">
          <h1 class="title is-1">
            {{user ? user.last_alias : 'Unknown User'}}
          </h1>
          <h4 class="subtitle is-4">
            {{user.score||0}} points
          </h4>
        </div>
      </div>

      <!-- Hero footer: will stick at the bottom -->
      <div class="hero-foot">
        <nav class="tabs is-boxed is-fullwidth">
          <div class="container">
            <ul>
              <li @click="setPage(0)" :class="{ 'is-active': page == 0 }"><a>Overview</a></li>
              <li @click="setPage(1)" :class="{ 'is-active': page == 1 }"><a>Campaign</a></li>
              <li @click="setPage(2)" :class="{ 'is-active': page == 2 }"><a>Versus</a></li>
              <li @click="setPage(3)" :class="{ 'is-active': page == 3 }" ><a>Survival</a></li>
              <li @click="setPage(4)" :class="{ 'is-active': page == 4 }" ><a>Scavenge</a></li>
            </ul>
          </div>
        </nav>
      </div>
    </section>
    <br>
    <div v-if="error">
      <b-message title="Error Ocurred" type="is-danger" aria-close-label="Close message">
        <strong>An error occurred while trying to acquire user.</strong>
        <p>{{this.error}}</p>
      </b-message>
    </div>
    <div v-else-if="not_found">
      <b-message title="User not found" type="is-warning" aria-close-label="Close message">
        Could not find any users with the steamid or username of <strong>{{$route.params.user}}</strong>
      </b-message>
    </div>
  <div v-cloak class="container" v-if="user.steamid">
    <div class="columns" v-if="page == 0"> 
      <div class="column">
        <h2 class='title is-2'>Stats Overview</h2>
        <h6 class="title is-6" id="playerstats">Player Information</h6>
        <table class="table is-fullwidth">
          <thead>
            <tr>
              <th width="30%">Stat Name</th>
              <th width="100%">Value</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>SteamID</td>
              <td class="tvalue">
                <p>
                {{user.steamid}}&nbsp;
                <a :href="'https://steamdb.info/calculator/' + communityID">[SteamDB]</a>&nbsp;
                <a :href="'https://steamcommunity.com/profiles/' + communityID">[Steam Community]</a>
                </p>
              </td>
            </tr>
            <tr>
              <td>Creation Date</td>
              <td class="tvalue">{{user.created_date | formatDateAndRel}}</td>
            </tr>
            <tr>
              <td>Last Played</td>
              <td class="tvalue">{{user.last_join_date | formatDateAndRel}}</td>
            </tr>
            <tr>
              <td>Last Location</td>
              <td class="tvalue">{{user.last_location}}</td>
            </tr>
            <tr>
              <td>Connections</td>
              <td class="tvalue">{{user.connections}}</td>
            </tr>
          </tbody>
        </table>
        <hr>
        <h6 class="title is-6">Kills</h6>
        <table class="table is-fullwidth">
          <thead>
            <tr>
              <th>Class</th>
              <th>As Survivor</th>
              <th>As Infected</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Smoker</td>
              <td>{{user.kills_smoker}}</td>
              <td></td>
            </tr>
            <tr>
              <td>Boomer</td>
              <td>{{user.kills_boomer}}</td>
              <td></td>
            </tr>
            <tr>
              <td>Hunter</td>
              <td>{{user.kills_hunter}}</td>
              <td></td>
            </tr>
            <tr>
              <td>Spitter</td>
              <td>{{user.kills_spitter}}</td>
              <td></td>
            </tr>
            <tr>
              <td>Charger</td>
              <td>{{user.kills_charger}}</td>
              <td></td>
            </tr>
            <tr>
              <td>Tank</td>
              <td>{{user.tanks_killed}}</td>
              <td></td>
            </tr>
          </tbody>
        </table>
        <table class="table is-fullwidth">
          <thead>
            <tr>
              <th>Class</th>
              <th>Kills</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Tank (Solo)</td>
              <td>{{user.tanks_killed_solo}}</td>
            </tr>
            <tr>
              <td>Tank (Melee Only)</td>
              <td>{{user.tanks_killed_melee}}</td>
            </tr>
            <tr>
              <td>Witch</td>
              <td>{{user.kills_witch}}</td>
            </tr>
            <tr>
              <td>Commons</td>
              <td>{{user.common_kills}}</td>
            </tr>
          </tbody>
        </table>
        <hr>
        <h6 class="title is-6">Survivor Stats</h6>
        <table class="table">
          <thead>
            <tr>
              <th>Stat Name</th>
              <th>Value</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>test</td>
              <td>value</td>
            </tr>
          </tbody>
        </table>
        <table class="table">
          <thead>
            <tr>
              <th>Stat Name</th>
              <th>Value</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(obj, key) in user" :key="key">
              <td>{{key}}</td>
              <td>{{obj}}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="column is-4">
        <div class="box">
          <h5 class="title is-5">Sections</h5>
          <ul>
            <li><a href="#playerinfo">Player Information</a></li>
            <li><a href="#kills">Kills</a></li>
            <li><a href="#times">Times</a></li>
          </ul>
        </div>
        <div class="box">
          <h5 class="title is-5">Best Map</h5>
          <span>
            <img :src="mapUrl" />
            <p>Dead Center</p>
          </span>
        </div>
      </div>
      
    </div>
  </div>
  <br>
  </div>
</template>

<script>
import Axios from 'axios'
import {format, formatDuration, formatDistanceToNow} from 'date-fns'
import SteamID from 'steamid'
export default {
  data() {
    return {
      user: {},
      error: null,
      not_found: false,
      page: 0
    }
  },
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
  mounted() {
    this.fetchUser();
  },
  methods: {
    fetchUser() {
      Axios.get(`/api/user/${this.$route.params.user}`)
      .then(response => {
        if(response.data.user) {
          this.user = response.data.user
        }else{
          this.not_found = true;
          this.page = -1;
        }
      })
      .catch(err => {
        this.err = err.message;
        this.page = -1;
        console.error('Fetch error',err)
      })
    },
    setPage(int) {
      if(!this.disabled) {
        this.page = int;
      }
    }
  },
  filters:{
    formatDate(inp) {
      return format(new Date(inp), "yyyy-MM-dd 'at' HH:mm")
    },
    formatDateAndRel(inp) {
      const _date = new Date(inp)
      const date = format(_date, "yyyy-MM-dd 'at' HH:mm");
      const rel = formatDistanceToNow(_date)
      return `${date} (${rel} ago)`
    },
    formatMinutes(min) {
      return formatDuration({minutes: min})
    }
  }
}
// function steamIDToProfile(steamID) {    
//     const parts = steamID.split(":");
    
//     const iServer = Number(parts[1]);
//     const iAuthID = Number(parts[2]);
    
//     let converted = "76561197960265728"

//     const lastIndex = converted.length - 1

//     const toAdd = iAuthID * 2 + iServer;
//     const toAddString = new String(toAdd)    
//     const addLastIndex = toAddString.length - 1;

//     for(let i=0; i<= addLastIndex; i++)
//     {
//         let num = Number(toAddString.charAt(addLastIndex - i));
//         let j = lastIndex - i;
//         do
//         {
//             const num2 = Number(converted.charAt(j));            
//             const sum = num + num2;        
                    
//             converted = converted.substr(0,j) + (sum % 10).toString() + converted.substr(j+1);    
        
//             num = Math.floor(sum / 10);            
//             j--;
//         }
//         while(num);
            
//     }
//     return converted;
// }
</script>



<style scoped>
.tvalue {
  width: 90%;
}
[v-cloak] {
  display: none;
}
</style>