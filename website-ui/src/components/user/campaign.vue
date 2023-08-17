<template>
<div v-if="!loading">
    <h2 class='title is-2'>Campaign Statistics</h2>
    <nav class="level">
        <b-loading :is-full-page="false" :active="loading" />
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Games Played</p>
            <p class="title">{{formatNumber(totals.wins)}}</p>
            </div>
        </div>
        <!-- <div class="level-item has-text-centered">
            <div>
            <p class="heading">Realism Games Played</p>
            <p class="title">{{formatNumber(totals.gamemodes.realism)}}</p>
            </div>
        </div> -->
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Easy Games Played</p>
            <p class="title">{{formatNumber(totals.difficulty.easy)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Normal Games Played</p>
            <p class="title">{{formatNumber(totals.difficulty.normal)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Advanced Games Played</p>
            <p class="title">{{formatNumber(totals.difficulty.advanced)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Expert Games Played</p>
            <p class="title">{{formatNumber(totals.difficulty.expert)}}</p>
            </div>
        </div>
    </nav>
    <hr>
    <b-table :data="maps">
        <b-table-column field="map" label="Map" v-slot="props">
            <router-link :to="'/maps/' + props.row.map">
                <strong>{{ formatMap(props.row.map)}}</strong>
            </router-link>
        </b-table-column>
        <b-table-column field="wins" label="Wins" centered cell-class="number-cell"  v-slot="props">
            {{ formatNumber(props.row.wins) }}
        </b-table-column>
        <!--<b-table-column field="realism" label="Times on Realism" centered cell-class="number-cell"  v-slot="props">
            {{ props.row.gamemodes.realism | formatNumber }}
        </b-table-column>-->
        <b-table-column field="difficulty.easy" label="Times on Easy" centered cell-class="number-cell"  v-slot="props">
            {{ formatNumber(props.row.difficulty.easy) }}
        </b-table-column>
        <b-table-column field="difficulty.normal" label="Times on Normal" centered cell-class="number-cell"  v-slot="props">
            {{ formatNumber(props.row.difficulty.normal) }}
        </b-table-column>
        <b-table-column field="difficulty.advanced" label="Times on Advanced" centered cell-class="number-cell"  v-slot="props">
            {{ formatNumber(props.row.difficulty.advanced) }}
        </b-table-column>
        <b-table-column field="difficulty.expert" label="Times on Expert" centered cell-class="number-cell"  v-slot="props">
            {{ formatNumber(props.row.difficulty.expert) }}
        </b-table-column>

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
import { getMapName } from '../../js/map'
export default {
  metaInfo() {
      return {
        title: "Campaigns"
      }
    },
    props: ['user'],
    data() {
        return {
            totals: {},
            maps: [],
            loading: true
        }
    },
    mounted() {
        this.fetchTotals()
    },
    methods: {
        formatMap(str) {
            return getMapName(str)
        },
        formatNumber(num) {
          return Number(num).toLocaleString()
        },
        fetchTotals() {
            this.loading = true;
            this.$http.get(`/api/user/${this.user.steamid}/totals/coop`,{cache:true})
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
