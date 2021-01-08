<template>
<div v-if="!loading">
    <h2 class='title is-2'>Campaign Statistics</h2>
    <nav class="level">
        <b-loading :is-full-page="false" :active="loading" />
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Games Played</p>
            <p class="title">{{totals.gamemodes.coop + totals.gamemodes.realism | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Realism Games Played</p>
            <p class="title">{{totals.gamemodes.realism | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Easy Games Played</p>
            <p class="title">{{totals.difficulty.easy | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Normal Games Played</p>
            <p class="title">{{totals.difficulty.normal | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Advanced Games Played</p>
            <p class="title">{{totals.difficulty.advanced | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Expert Games Played</p>
            <p class="title">{{totals.difficulty.expert | formatNumber}}</p>
            </div>
        </div>
    </nav>
    <hr>
    <b-table :data="maps">
        <template slot-scope="props">
            <b-table-column field="map" label="Map" >
                <router-link :to="'/maps/' + props.row.map">
                    <strong>{{ props.row.map | formatMap }}</strong>
                </router-link>
            </b-table-column>
            <b-table-column field="wins" label="Wins" centered cell-class="number-cell">
                {{ props.row.gamemodes.coop + props.row.gamemodes.realism | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Realism" centered cell-class="number-cell">
                {{ props.row.gamemodes.realism | formatNumber }}
            </b-table-column>
            <b-table-column field="difficulty.easy" label="Times on Easy" centered cell-class="number-cell">
                {{ props.row.difficulty.easy | formatNumber }}
            </b-table-column>
            <b-table-column field="difficulty.normal" label="Times on Normal" centered cell-class="number-cell">
                {{ props.row.difficulty.normal | formatNumber }}
            </b-table-column>
            <b-table-column field="difficulty.advanced" label="Times on Advanced" centered cell-class="number-cell">
                {{ props.row.difficulty.advanced | formatNumber }}
            </b-table-column>
            <b-table-column field="difficulty.expert" label="Times on Expert" centered cell-class="number-cell">
                {{ props.row.difficulty.expert | formatNumber }}
            </b-table-column>
        </template>
        <template slot="empty">
            <section class="section">
                <div class="content has-text-grey has-text-centered">
                    <p>{{user.last_alias}} has no recorded campaign statistics</p>
                </div>
            </section>
        </template>
    </b-table>
</div>
</template>

<script>
import { formatDuration } from 'date-fns'
import { getMapName } from '../../js/map'
export default {
    props: ['user'],
    data() {
        return {
            totals: {},
            maps: [],
            loading: true
        }
    },
    filters: {
        formatMap(str) {
            return getMapName(str)
        },
        formatMS(inp) {
            return formatDuration({seconds: inp / 1000})
        }
    },
    mounted() {
        this.fetchTotals()
        document.title = `Campaign - ${this.user.last_alias}'s Profile - L4D2 Stats Plugin`
    },
    methods: {
        fetchTotals() {
            this.loading = true;
            this.$http.get(`/api/user/${this.user.steamid}/totals`,{cache:true})
            .then(r => {
                this.totals = r.data.totals;
                this.maps = r.data.maps
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch campaign statistics',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchTotals()
                })
            })
            .finally(() => this.loading = false)
        }
    }
}
</script>

<style>
.number-cell {
    color: blue;
}
</style>