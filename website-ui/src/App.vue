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
            <!-- <b-navbar-item tag="router-link" to="/maps">
                Maps List
            </b-navbar-item> -->
            <b-navbar-item tag="router-link" to="/summary">
                Summary
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/campaigns">
                Campaigns
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/sessions">
                Sessions
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/faq">
                FAQ
            </b-navbar-item>
        </template>

        <template slot="end">
            <b-navbar-item>
              <form @submit.prevent="searchUser">
              <b-field>
                  <b-autocomplete
                    v-debounce:400ms="onSearchAutocomplete"
                    v-model="search.query"
                    placeholder="Search for user..."  
                    icon="search"
                    :data="search.autocomplete"
                    clearable
                    field="last_alias"
                    @select="onSearchSelect"
                    @enter.native="searchUser"
                    clear-on-select
                    expanded
                    :loading="search.loading"
                    >
                    <template slot="empty">No users were found</template>
                    <template  v-slot:default="props">
                      <b>{{props.option.last_alias}}</b> ({{props.option.steamid}})
                    </template>
                  </b-autocomplete>
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
    <keep-alive :max="5">
      <router-view />
    </keep-alive>
  </div>
</template>

<script>
export default {
  computed: {
    title() {
      return process.env.VUE_APP_SITE_NAME
    },
    version() {
      return `v${process.env.VUE_APP_VERSION}`
    }
  },
  data() {
    return {
      search: {
        query: null,
        last_autocomplete: null,
        autocomplete: [],
        loading: false
      },
    }
  },
  methods: {
    searchUser() {
      const query = this.search.query.trim();
      if(query.length == 0) return;
      if(this.$route.name === "Search") {
        this.$router.replace(`/search/${query}`)
      }else{
        this.$router.push(`/search/${query}`)
      }
    },
    onSearchAutocomplete() {
      this.loading = true;
      const query = this.search.query.trim();
      if(query.length == 0 || this.search.last_autocomplete == query) return;
      this.$http.get(`/api/search/${query}`,{cache:true})
      .then(res => {
          this.search.autocomplete = res.data;
          this.search.last_autocomplete = query;
      }) 
      .catch(err => {
          console.error('Failed to fetch autocomplete results', err)
      })
      .finally(() => this.loading = false)
    },
    onSearchSelect(obj) {
      if(obj) {
        this.$router.push('/user/' + obj.steamid)
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
