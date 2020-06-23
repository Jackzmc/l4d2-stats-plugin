<template>
  <div id="app">
    <b-navbar>
        <template slot="brand">
            <b-navbar-item tag="router-link" to="/">
                <h5 class="title is-5">{{title}}</h5>
            </b-navbar-item>
        </template>
        <template slot="start">
            <b-navbar-item  tag="router-link" to="/">
                Home
            </b-navbar-item>
            <b-navbar-item  tag="router-link" to="/top">
                Leaderboards
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/maps">
                Maps List
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/faq">
                FAQ
            </b-navbar-item>
        </template>

        <template slot="end">
            <b-navbar-item>
              <form @submit.prevent="searchUser">
              <b-field>
                <b-input v-model="search" placeholder="Search for user..."  icon="search">
                </b-input>
                <p class="control">
                  <input type="submit" class="button is-info" value="Search"/>
                </p>
              </b-field>
              </form>
            </b-navbar-item>
            <b-navbar-item tag="div">
                {{version}}
            </b-navbar-item>
        </template>
    </b-navbar>
    <router-view/>
  </div>
</template>

<script>
export default {
  computed: {
    title() {
      return process.env.VUE_APP_SITE_NAME || 'L4D2 Stats Plugin';
    },
    version() {
      return `v${process.env.VUE_APP_VERSION}`
    }
  },
  mounted() {
    document.title = process.env.VUE_APP_SITE_NAME;
  },
  data() {
    return {
      search: null
    }
  },
  methods: {
    searchUser() {
      if(this.$route.name === "Search") {
        this.$router.replace(`/search/${this.search}`)
      }else{
        this.$router.push(`/search/${this.search}`)
      }
    }
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
}

#nav {
  padding: 30px;
}

#nav a {
  font-weight: bold;
  color: #2c3e50;
}

#nav a.router-link-exact-active {
  color: #42b983;
}
</style>
