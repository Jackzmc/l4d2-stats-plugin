<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
            <h1 class="title">
                Statistics
            </h1>
            <p class="subtitle is-4">A summarization of all recorded sessions.</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container">
        <b-message title="Notice" type="is-warning" :closable="false">
            This page is still in development. Please check back later.
        </b-message>
        <pre v-if="!loading" class="has-text-left" v-html="colorizeJSON(tmp)"></pre>
    </div>
</div>
</template>

<script>
export default {
    data() {
        return {
            top_map: null,
            btm_map: null,
            stats: null,
            loading: true,
            tmp: null
        }
    },
    mounted() {
        this.fetchStats();
    },
    methods: {
        fetchStats() {
            this.loading = true;
            this.$http.get(`/api/summary`, { cache: true })
            .then(r => {
                this.tmp = r.data
                this.top_map = r.data.top_map;
                this.btm_map = r.data.btm_map;
                this.stats = r.data.stats;
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch stat summary',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchStats()
                })
            })
            .finally(() => this.loading = false)
        },
        colorizeJSON(obj) {
            const str = JSON.stringify(obj, null, 2).split("\n");
            const lines = [];
            for(const line of str) {
                const numberMatch = line.match(/(\d+\.?\d*),?$/);
                const strMatch = line.match(/("[0-9a-zA-Z_]+"),?$/);
                if(numberMatch && numberMatch.length > 0) {
                    lines.push(line.replace(/(\d+\.?\d*),?$/, `<span class='has-text-link'>${numberMatch[0]}</span>`))
                }else if(strMatch && strMatch.length > 0) {
                    lines.push(line.replace(/("[0-9a-zA-Z_]+"),?$/, `<span class='has-text-danger'>${strMatch[0]}</span>`))
                }else{
                    lines.push(line)
                }
            }
            return lines.join("\n");
        }
    }
}
</script>