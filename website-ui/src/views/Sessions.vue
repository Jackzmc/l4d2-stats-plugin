<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
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
            <template slot-scope="props">
                <b-table-column label="View">
                    <b-button type="is-info" tag="router-link" size="is-small" :to="'/sessions/details/' + props.row.id">
                        View
                    </b-button>
                </b-table-column>
                <b-table-column field="steamid" label="User" >
                    <router-link :to='"/user/" + props.row.steamid'>{{props.row.steamid}}</router-link>
                </b-table-column>
                <b-table-column field="map" label="Map" >
                    {{ getMapNameByChapter(props.row.map) }}
                </b-table-column>
                <b-table-column field="zombieKills" label="Zombie Kills" centered cell-class="number-cell">
                    {{ props.row.zombieKills | formatNumber }}
                </b-table-column>
                <b-table-column field="survivorDamage" label="Friendly Fire" centered cell-class="number-cell">
                    {{ props.row.survivorDamage | formatNumber }}
                </b-table-column>
                <b-table-column field="MedkitsUsed" label="Medkits Used" centered cell-class="number-cell">
                    {{ props.row.MedkitsUsed | formatNumber }}
                </b-table-column>
                <b-table-column label="Total Throwables" centered cell-class="number-cell">
                    {{ getThrowableCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column label="Total Pills/Shots Used" centered cell-class="number-cell">
                    {{ getPillShotCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column field="incaps" label="Incaps" centered cell-class="number-cell">
                    {{ props.row.incaps | formatNumber }}
                </b-table-column>
                <b-table-column field="deaths" label="Deaths" centered cell-class="number-cell">
                    {{ props.row.deaths | formatNumber }}
                </b-table-column>
                <b-table-column field="DamageTaken" label="Damage Taken" centered cell-class="number-cell">
                    {{ props.row.DamageTaken | formatNumber }}
                </b-table-column>
                <b-table-column field="difficulty" label="Difficulty" centered>
                    {{ formatDifficulty(props.row.difficulty) }}
                </b-table-column>
            </template>
            <template slot="detail" slot-scope="props">
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
import { getMapNameByChapter } from '../js/map'
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
        getMapNameByChapter,
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
                case 4: return "Expert"
            }
        }
    }
}
</script>