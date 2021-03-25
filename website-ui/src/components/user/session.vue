<template>
<div>
    <h2 class='title is-2'>Games Played</h2>
    <p class="subtitle is-4">{{total_sessions}} total sessions</p>
    <b-table
        :data="sessions"
        :loading="loading"

        paginated
        backend-pagination
        :current-page="current_page"
        per-page=20
        :total="total_sessions"
        @page-change="onPageChange"
    >
          <b-table-column label="View" v-slot="props">
              <b-button type="is-info" tag="router-link" size="is-small" :to="'/sessions/details/' + props.row.id + '?from=' + user.steamid">
                  View
              </b-button>
          </b-table-column>
          <b-table-column field="map" label="Map" v-slot="props">
              {{ getMapName(props.row.map) }}
          </b-table-column>
          <b-table-column field="zombieKills" label="Zombie Kills" centered cell-class="number-cell" v-slot="props">
              {{ props.row.zombieKills | formatNumber }}
          </b-table-column>
          <b-table-column field="survivorDamage" label="Friendly Fire" centered cell-class="number-cell" v-slot="props">
              {{ props.row.SurvivorDamage | formatNumber }}
          </b-table-column>
          <b-table-column field="MedkitsUsed" label="Medkits Used" centered cell-class="number-cell" v-slot="props">
              {{ props.row.MedkitsUsed | formatNumber }}
          </b-table-column>
          <b-table-column label="Total Throwables" centered cell-class="number-cell"  v-slot="props">
              {{ getThrowableCount(props.row) | formatNumber }}
          </b-table-column>
          <b-table-column label="Total Pills/Shots Used" centered cell-class="number-cell" v-slot="props">
              {{ getPillShotCount(props.row) | formatNumber }}
          </b-table-column>
          <b-table-column field="incaps" label="Incaps" centered cell-class="number-cell" v-slot="props">
              {{ props.row.incaps | formatNumber }}
          </b-table-column>
          <b-table-column field="deaths" label="Deaths" centered cell-class="number-cell" v-slot="props">
              {{ props.row.deaths | formatNumber }}
          </b-table-column>
          <b-table-column field="DamageTaken" label="Damage Taken" centered cell-class="number-cell" v-slot="props">
              {{ props.row.DamageTaken | formatNumber }}
          </b-table-column>
          <b-table-column field="difficulty" label="Difficulty" centered v-slot="props" >
              {{ formatDifficulty(props.row.difficulty) }}
          </b-table-column>
        <template slot="empty">
            <section class="section">
                <div class="content has-text-grey has-text-centered">
                    <p>{{user.last_alias}} has no recorded sessions</p>
                </div>
            </section>
        </template>
    </b-table>
</div>
</template>

<script>
import { getMapName } from '../../js/map'
export default {
    props: ['user'],
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
        document.title = `Sessions - ${this.user.last_alias}'s Profile - L4D2 Stats Plugin`
    },
    methods: {
        getMapName,
        fetchSessions() {
            this.loading = true;
            this.$http.get(`/api/user/${this.user.steamid}/sessions/${this.current_page}`, { cache: true })
            .then(r => {
                this.sessions = r.data.sessions;
                this.total_sessions = r.data.total;
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
        }
    }
}
</script>

<style>
.number-cell {
    color: blue;
}
</style>
