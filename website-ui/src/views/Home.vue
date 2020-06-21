<template>
  <div class="home container">
    <br>
    <div class="columns">
      <div class="column">
        <h3 class="title is-3">Top Players (Today)</h3>
        <br>
        <b-table :data="top_today">
          <template slot-scope="props">
            <b-table-column field="last_alias" label="Player" >
                <router-link :to="'/user/' + props.row.steamid">{{ props.row.last_alias }}</router-link>
            </b-table-column>
            <b-table-column field="points" label="Points" >
                {{ props.row.points }}
            </b-table-column>
            <b-table-column field="top_gamemode" label="Top Gamemode" >
                {{ props.row.top_gamemode }}
            </b-table-column>
            <b-table-column field="minutes_played" label="Total Playtime" >
                {{ props.row.minutes_played | formatMinutes }}
            </b-table-column>
          </template>
        </b-table>
      </div>
      <div class="column is-4">
        <div class="box">
          <h5 class='title is-5'>Categories</h5>
        </div>
        <div class="box">
          <h5 class='title is-5'>Find Player</h5>
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
      search: ''
    }
  },
  mounted() {
    this.refreshTop();
  },
  methods: {
    refreshTop() {
      Axios.get('/api/top/daily')
      .then((r) => {
        this.top_today = r.data;
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
      this.$buefy.snackbar.open({
        type: 'is-warning',
        position: 'is-top',
        message: 'Search is currently not implemented'
      })
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
