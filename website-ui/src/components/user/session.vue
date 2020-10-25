<template>
<div>
    <h3 class='title is-3'>Games Played</h3>
    <b-table :data="sessions" detailed>
        <template slot-scope="props">
            <b-table-column width="20">
                <b-tooltip label="View Details">
                    <router-link icon-right="angle-right">
                        <b-icon icon="angle-right" />
                    </router-link>
                </b-tooltip>
            </b-table-column>
            <b-table-column field="zombieKills" label="Zombie Kills" centered cell-class="number-cell">
                {{ props.row.zombieKills | formatNumber }}
            </b-table-column>
            <b-table-column field="survivorDamage" label="Friendly Fire" centered cell-class="number-cell">
                {{ props.row.survivorDamage | formatNumber }}
            </b-table-column>
            <b-table-column field="throwables" label="Total Throwables" centered cell-class="number-cell">
                {{ getThrowableCount(props.row) | formatNumber }}
            </b-table-column>
            <b-table-column field="deaths" label="Deaths" centered cell-class="number-cell">
                {{ props.row.deaths | formatNumber }}
            </b-table-column>
            <b-table-column field="DamageTaken" label="Damage Taken" centered cell-class="number-cell">
                {{ props.row.DamageTaken | formatNumber }}
            </b-table-column>
            <b-table-column field="difficulty" label="Difficulty" centered cell-class="number-cell">
                {{ formatDifficulty(props.row.difficulty) }}
            </b-table-column>
        </template>
        <template slot="detail" slot-scope="props">
            {{props.row}}
        </template>
        <template slot="empty">
            <section class="section">
                <div class="content has-text-grey has-text-centered">
                    <p>{{user.last_alias}} has no recorded game sessions</p>
                </div>
            </section>
        </template>
    </b-table>
</div>
</template>

<script>
export default {
    props: ['user'],
    data() {
        return {
            sessions: [],
            loading: true
        }
    },
    mounted() {
        this.fetchSessions()
        document.title = `Sessions - ${this.user.last_alias}'s Profile - L4D2 Stats Plugin`
    },
    methods: {
        fetchSessions() {
            this.loading = true;
            this.$http.get(`/api/user/${this.user.steamid}/sessions`, { cache: true })
            .then(r => {
                this.sessions = r.data;
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
        getThrowableCount(session) {
            return session.MolotovsUsed + session.PipebombsUsed + session.BoomerBilesUsed;
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

<style>
.number-cell {
    color: blue;
}
</style>