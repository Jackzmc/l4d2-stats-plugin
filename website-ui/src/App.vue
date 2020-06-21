<template>
  <div id="app">
    <b-navbar>
        <template slot="brand">
            <b-navbar-item tag="router-link" :to="{ path: '/' }">
                <h4 class="title is-4">{{title}}</h4>
            </b-navbar-item>
        </template>
        <template slot="start">
            <b-navbar-item href="/">
                Home
            </b-navbar-item>
            <b-navbar-item href="/maps">
                Maps List
            </b-navbar-item>
        </template>

        <template slot="end">
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
