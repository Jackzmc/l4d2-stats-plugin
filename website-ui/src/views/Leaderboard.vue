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
    <div class="container is-fluid">
      <div class="columns">
        <div class="column">
          <ProfileList :data="top_today" striped sticky-header :loading="loading" />
        </div>
        <div class="column is-3">
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
import ProfileList from '@/components/ProfileList'
export default {
  name: 'Leaderboard',
  components: {
    ProfileList
  },
  data() {
    return {
      top_today: [],
      failure: false,
      players_total: 0,
      search: '',
      loading: true
    }
  },
  mounted() {
    this.refreshTop();
  },
  methods: {
    refreshTop() {
      this.loading = true;
      this.$http.get('/api/top',{cache:true})
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
      }).finally(() => this.loading = false)
    },
    searchUser() {
      if(this.search.trim().length > 0)
        this.$router.push(`/search/${this.search.trim()}`)
    }
  },
  metaInfo: [
    { name: 'og:title', content: "Leaderboards - L4D2 Stats Plugin"}
  ]
}
</script>
