<template>
<div class="aboutis-fluid">
  <section class="hero is-info">
    <!-- Hero head: will stick at the top -->

    <!-- Hero content: will be in the middle -->
    <div v-cloak class="hero-body">
      <div class="container has-text-centered">
        <h1 class="title is-1">
          {{user.steamid ? user.last_alias : 'Unknown User'}}
        </h1>
        <h4 class="subtitle is-4">
          {{user.points||0 | formatNumber}} points
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
            <!-- <router-link tag="li" to="versus"><a>Versus</a></router-link>
            <router-link tag="li" to="survival"><a>Survival</a></router-link>
            <router-link tag="li" to="scavenge"><a>Scavenge</a></router-link> -->
          </ul>
        </div>
      </nav>
    </div>
  </section>
  <br>
  <div v-if="error" class="container">
    <b-message title="Error Ocurred" type="is-danger" aria-close-label="Close message" :closable="false">
      <strong>An error occurred while trying to acquire user.</strong>
      <p>{{this.error}}</p>
    </b-message>
  </div>
  <div v-else-if="not_found" class="container">
    <b-message title="User not found" type="is-warning" aria-close-label="Close message" :closable="false">
      Could not find any users with the steamid or username of <strong>{{$route.params.user}}</strong>
    </b-message>
  </div>
  <div class="container" v-if="user.steamid">
    <transition name="slide" :duration="200">
      <keep-alive>
        <router-view :user="user" :maps="maps" :key="$route.fullPath"></router-view>
      </keep-alive>
    </transition>
  </div>
  <br>
  <br>
</div>
</template>

<script>
import 'vue2-animate/dist/vue2-animate.min.css'
import SteamID from 'steamid';
export default {
  data() {
    return {
      user: {},
      maps: [],
      error: null,
      not_found: false,
    }
  },
  mounted() {
    this.fetchUser();
  },
  watch: {
    // call again the method if the route changes
    '$route': 'fetchUser'
  },
  methods: {
    fetchUser() {
      this.error = null;
      this.not_found = false;
      try {
        const steamid = new SteamID(this.$route.params.user);

        if(!steamid.isValid()) {
          this.error = "Specified user's ID is not a valid steamID. Possible formats are: 76561198058753262 or STEAM_0:0:23071901"
          return
        }
        const id = steamid.getSteam2RenderedID(true);
        this.$http.get(`/api/user/${id}`,{cache:true})
        .then(response => {
          if(response.data.user) {
            this.user = response.data.user
            this.maps = response.data.maps || []
            document.title = `${this.user.last_alias}'s Profile - L4D2 Stats Plugin`
          }else{
            this.not_found = true;
          }
        })
        .catch(err => {
          this.err = err.message;
          console.error('Fetch error',err)
        })
      }catch(err) {
        this.error = err.message
      }
    }
  }
}
</script>



<style scoped>
[v-cloak] {
  display: none;
}
.hero {
  background: linear-gradient(180deg, #008cff 0%, #3a47d5 100%);
}
</style>