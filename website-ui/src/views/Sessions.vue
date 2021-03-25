<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Sessions
            </h1>
            <p class="subtitle is-4">{{total_sessions | formatNumber}} total sessions</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container is-fluid">
        <b-table
            :data="sessions"
            :loading="loading"

            paginated
            backend-pagination
            :current-page="current_page"
            per-page=12
            :total="total_sessions"
            @page-change="onPageChange"

        >
        <!-- TODO: background sort -->
                <b-table-column v-slot="props" label="View">
                    <b-button tag="router-link" :to="'/sessions/details/' + props.row.id" expanded  :style="'background-color:' + getRGB(props.row.campaignID)"> View</b-button>
                </b-table-column>
                <b-table-column v-slot="props" field="steamid" label="User">
                    <router-link :to='"/user/" + props.row.steamid'><b>{{props.row.last_alias}}</b></router-link>
                </b-table-column>
                <b-table-column v-slot="props" field="map" label="Map">
                    {{ getMapName(props.row.map) }}
                </b-table-column>
                <b-table-column v-slot="props" field="survivorDamage" label="Friendly Fire" centered cell-class="number-cell">
                    {{ props.row.SurvivorDamage | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="DamageTaken" label="Damage Taken" centered cell-class="number-cell">
                    {{ props.row.DamageTaken | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="MedkitsUsed" label="Medkits Used" centered cell-class="number-cell">
                    {{ props.row.MedkitsUsed | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" label="Total Throwables" centered cell-class="number-cell">
                    {{ getThrowableCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" label="Total Pills/Shots Used" centered cell-class="number-cell">
                    {{ getPillShotCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="incaps" label="Incaps" centered cell-class="number-cell">
                    {{ props.row.incaps | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="deaths" label="Deaths" centered cell-class="number-cell">
                    {{ props.row.deaths | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="difficulty" label="Difficulty" centered>
                    {{ formatDifficulty(props.row.difficulty) }}
                </b-table-column>
            <template #detail="props">
              <pre>{{props.row}}</pre>
            </template>
            <template slot="empty">
                <section class="section">
                    <div class="content has-text-grey has-text-centered">
                        <p>There are no recorded sessions</p>
                    </div>
                </section>
            </template>
        </b-table>
    </div>
</div>
</template>

<script>
import { getMapName } from '../js/map'
export default {
    data() {
        return {
            sessions: [],
            loading: true,
            current_page: 1,
            total_sessions: 0
        }
    },
    mounted() {
        let routerPage = parseInt(this.$route.params.page);
        if(isNaN(routerPage) || routerPage <= 0) routerPage = 1;
        this.current_page = routerPage;
        this.fetchSessions()
        document.title = `Sessions - L4D2 Stats Plugin`
    },
    methods: {
        getMapName,
        fetchSessions() {
            this.loading = true;
            this.$http.get(`/api/sessions/?page=${this.current_page}&perPage=12`, { cache: true })
            .then(r => {
                this.sessions = r.data.sessions;
                this.total_sessions = r.data.total_sessions;
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch game sessions.',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchSessions()
                })
            })
            .finally(() => this.loading = false)
        },
        onPageChange(page) {
            this.current_page = page;
            this.$router.replace({params: {page}})
            this.fetchSessions();
        },
        getThrowableCount(session) {
            return session.MolotovsUsed + session.PipebombsUsed + session.BoomerBilesUsed;
        },
        getPillShotCount(session) {
            return session.AdrenalinesUsed + session.PillsUsed
        },
        formatDifficulty(difficulty) {
            switch(difficulty) {
                case 0: return "Easy"
                case 1: return "Normal";
                case 2: return "Advanced"
                case 3: return "Expert"
            }
        },
        getRGB(campaignID) {
            if(!campaignID) return "#0f77ea"
            return "#" + dec2hex(campaignID.replace(/[^0-9]/g,'')).substring(0,6)
        }
    }
}
function dec2hex(str){ // .toString(16) only works up to 2^53
    var dec = str.toString().split(''), sum = [], hex = [], i, s
    while(dec.length){
        s = 1 * dec.shift()
        for(i = 0; s || i < sum.length; i++){
            s += (sum[i] || 0) * 10
            sum[i] = s % 16
            s = (s - sum[i]) / 16
        }
    }
    while(sum.length){
        hex.push(sum.pop().toString(16))
    }
    return hex.join('')
}
</script>
<style>
.number-cell {
  color: blue;
}
.table td {
    vertical-align: middle;;
}
</style>
