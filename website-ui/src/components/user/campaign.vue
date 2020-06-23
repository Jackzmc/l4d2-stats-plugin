<template>
<div>
    <h2 class='title is-2'>Campaign Statistics</h2>
    <nav class="level">
        <b-loading :is-full-page="false" :active="loading" />
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Total Finales Won</p>
            <p class="title">{{totals.wins | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Realism Games Played</p>
            <p class="title">{{totals.realism | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Easy Games Played</p>
            <p class="title">{{totals.easy | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Normal Games Played</p>
            <p class="title">{{totals.normal | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Advanced Games Played</p>
            <p class="title">{{totals.advanced | formatNumber}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Expert Games Played</p>
            <p class="title">{{totals.expert | formatNumber}}</p>
            </div>
        </div>
    </nav>
    <hr>
    <br>
    <h6 class="title is-6">Map Statistics</h6>
    <b-table :data="maps" detailed>
        <template slot-scope="props">
            <b-table-column field="map_name" label="Map" >
                <router-link :to="'/maps/' + props.row.map_name">
                    <strong>{{ props.row.map_name | formatMap }}</strong>
                </router-link>
            </b-table-column>
            <b-table-column field="wins" label="Wins" centered cell-class="number-cell">
                {{ props.row.wins | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Realism" centered cell-class="number-cell">
                {{ props.row.realism | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Easy" centered cell-class="number-cell">
                {{ props.row.difficulty_easy | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Normal" centered cell-class="number-cell">
                {{ props.row.difficulty_normal | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Advanced" centered cell-class="number-cell">
                {{ props.row.difficulty_advanced | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Expert" centered cell-class="number-cell">
                {{ props.row.difficulty_expert | formatNumber }}
            </b-table-column>
        </template>
        <template slot="detail" slot-scope="props">
            <p><strong>Map: </strong>{{props.row.map_name}}</p>
            <hr>
            <h5 class="title is-5">Best Time</h5>
            <p class="subtitle is-6">{{props.row.best_time | formatMs}}</p>
        </template>
        <template slot="empty">
            <section class="section">
                <div class="content has-text-grey has-text-centered">
                    <p>{{user.last_alias}} has no recorded finale statistics</p>
                </div>
            </section>
        </template>
    </b-table>
</div>
</template>

<script>
import {formatDuration} from 'date-fns'
import Axios from 'axios'
export default {
    props: ['user', 'maps'],
    data() {
        return {
            totals:{},
            loading: true
        }
    },
    filters: {
        formatMap(str) {
            switch(str.substring(0,3)) {
                case "c1m": return "Dead Center"
                case "c2m": return "Dark Carnival"
                case "c3m": return "Swamp Fever"
                case "c4m": return "Hard Rain"
                case "c5m": return "The Parish"
                case "c6m": return "The Passing"
                case "c7m": return "The Sacrifice"
                case "c8m": return "No Mercy"
                case "c9m": return "Death Toll"
                case "c10": return "Crash Course"
                case "c11": return "Dead Air"
                case "c12": return "Blood Harvest"
                case "c13": return "Cold Stream"
                default: return str;
            }
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
            Axios.get(`/api/user/${this.user.steamid}/campaign`)
            .then(r => {
                this.totals = r.data.campaign;
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch campaign total statistics',
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