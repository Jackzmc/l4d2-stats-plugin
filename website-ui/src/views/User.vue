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
          {{user.points||0}} points
        </h4>
      </div>
    </div>

    <!-- Hero footer: will stick at the bottom -->
    <div class="hero-foot">
      <nav class="tabs is-boxed is-fullwidth">
        <div class="container">
          <ul>
            <router-link tag="li" to="overview"><a>Overview</a></router-link>
            <router-link tag="li" to="campaign"><a>Campaign</a></router-link>
            <router-link tag="li" to="versus"><a>Versus</a></router-link>
            <router-link tag="li" to="survival"><a>Survival</a></router-link>
            <router-link tag="li" to="scavenge"><a>Scavenge</a></router-link>
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
  <div class="container" v-if="user.steamid">
    <router-view :user="user" :maps="maps"></router-view>
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
      maps: [],
      error: null,
      not_found: false,
    }
  },
  components: {
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
          this.maps = response.data.maps || []
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
        if(int == 0) this.$router.push('overview')
        else if(int == 1) this.$router.push('campaign')
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
</script>



<style scoped>
[v-cloak] {
  display: none;
}
</style>