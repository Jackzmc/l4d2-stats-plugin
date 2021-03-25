<template>
<div class="home">
    <section class="hero is-primary is-bold">
    <div class="hero-body">
        <div class="container has-text-centered">
        <h1 class="title">
            L4D2 Statistics Plugin
        </h1>
        <h2 class="subtitle">
            <p>Created by <a href="https://github.com/jackzmc">Jackzmc</a></p>
            <br>
            <b-button rounded type="is-info" tag="a" href="https://github.com/jackzmc/l4d2-stats-plugin">View Source</b-button>
        </h2>
        </div>
    </div>
    </section>
    <br>
    <div class="container">
       <h4 class="title is-4">Information</h4>
       <p>
           This homepage is still being worked on. Why not check out the <router-link to="/top">leaderboards?</router-link>
        </p>
        <!-- TODO: show online users? -->
    </div>
</div>
</template>

<script>
export default {
    metaInfo: [
        { name: 'og:title', content: "L4D2 Stats Plugin"}
    ]
}
</script>
