<template>
  <div class="home">
    <section class="hero is-dark">
      <div class="hero-body">
        <div class="container">
          <h1 class="title">
            L4D2 Leaderboards
          </h1>
          <h2 class="subtitle">
            <p>Showing top <strong>{{top_today.length}} players</strong> out of <strong>{{players_total | formatNumber}} total</strong></p>
          </h2>
        </div>
      </div>
    </section>
    <br>
    <div class="container">
      <div class="columns">
        <div class="column">
          <b-table :data="top_today" striped sticky-header>
            <template slot-scope="props">
              <b-table-column width="20">
                <router-link :to="'/user/' + props.row.steamid" icon-right="angle-right">
                  <b-icon icon="angle-right" />
                </router-link>
              </b-table-column>
              <b-table-column field="last_alias" label="Player" >
                <router-link :to="'/user/' + props.row.steamid">
                  <strong>{{ props.row.last_alias }}</strong>
                </router-link>
              </b-table-column>
              <b-table-column field="points" label="Points" >
                <span class="has-text-info">{{ props.row.points | formatNumber }}</span>
              </b-table-column>
              <b-table-column field="top_gamemode" label="Top Gamemode" >
                  {{ props.row.top_gamemode }}
              </b-table-column>
              <b-table-column field="minutes_played" label="Total Playtime" >
                  <span class="has-text-info">{{ props.row.minutes_played | formatMinutes }}</span>
              </b-table-column>
            </template>
          </b-table>
        </div>
        <div class="column is-4">
          <div class="box">
            <form @submit.prevent="searchUser">
            <b-field label="Enter Username or Steam ID">
              <b-field>
                <b-input v-model="search" placeholder="STEAM_1:0:49243767"  icon="search">
                </b-input>
                <p class="control">
                  <input type="submit" class="button is-info" value="Search"/>
                </p>
              </b-field>
            </b-field>
            </form>
          </div>
          <div class="box">
            <h5 class='title is-5'>Categories</h5>
            <b-menu-list>
              <b-menu-item label="Top Overall"></b-menu-item>
              <b-menu-item label="Top Campaign"></b-menu-item>
              <b-menu-item label="Top Versus"></b-menu-item>
              <b-menu-item label="Top Survival"></b-menu-item>
              <b-menu-item label="Top Scavenge"></b-menu-item>
            </b-menu-list>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
// @ is an alias to /src
import Axios from 'axios'
import {formatDuration} from 'date-fns'
export default {
  name: 'Home',
  components: {
  },
  data() {
    return {
      top_today: [],
      failure: false,
      players_total: 0,
      search: ''
    }
  },
  mounted() {
    this.refreshTop();
  },
  methods: {
    refreshTop() {
      Axios.get('/api/top')
      .then((r) => {
        this.top_today = r.data.users;
        this.players_total = r.data.total_users;
      })
      .catch(err => {
        this.failure = true;
        console.error('Fetch error', err)
        this.$buefy.snackbar.open({
            duration: 5000,
            message: 'Error ocurred while fetching top players for today.',
            type: 'is-danger',
            position: 'is-bottom-left',
            actionText: 'Retry',
            onAction: () => this.refreshTop()
        })
      })
    },
    searchUser() {
      this.$router.push(`/search/${this.search}`)
    }
  },
  filters: {
    humanReadable(minutes) {
      let hours = Math.floor(minutes / 60);  
      const days = Math.floor(hours / 24);
      minutes = minutes % 60;
      const min_text = minutes == 1 ? 'minute' : 'minutes'
      const hour_text = hours == 1 ? 'hour' : 'hours'
      if(days >= 1) {
        hours = hours % 24; 
        return `${days} days, ${hours} ${hour_text}`
      }else if(hours >= 1) {
        return `${hours} ${hour_text}, ${minutes} ${min_text}` 
      }else{
        return `${minutes} ${min_text}`
      }
    },
    formatMinutes(min) {
      return formatDuration({minutes: min})
    }
  }
}
</script>
