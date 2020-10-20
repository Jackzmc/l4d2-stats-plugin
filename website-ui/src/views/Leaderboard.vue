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
          <ProfileList 
            height="100%" 
            :data="top_today"
            :loading="loading" 

            striped sticky-header 
            paginated 
            backend-pagination 
            :current-page="top_page" 
            per-page=10
            :total="players_total" 

            @page-change="onTopPageChange" 
          />
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
      top_page: 1,
      failure: false,
      players_total: 0,
      search: '',
      loading: true
    }
  },
  mounted() {
    let currentRoutePage = !isNaN(this.$route.params.page) ? parseInt(this.$route.params.page) : 0
    if(currentRoutePage <= 0) currentRoutePage = 1;
    this.top_page = currentRoutePage;
    this.refreshTop();
  },
  methods: {
    refreshTop() {
      console.debug('Loading users for page' + this.top_page)
      this.loading = true;
      this.$http.get(`/api/top/${this.top_page}`, { cache: true })
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
    onTopPageChange(page) {
      this.top_page = page;
      this.$router.replace(`/top/${page}`)
        this.refreshTop();

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
