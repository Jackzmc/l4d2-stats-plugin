<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Statistics
            </h1>
            <p class="subtitle is-4">A summarization of all recorded sessions</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container" v-if="totals && averages">
        <p class="title is-6">Totals</p>
        <nav class="level">
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Games Played</p>
                <p class="title"><ICountUp :endVal="totals.total_games" /></p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Total Playtime</p>
                <p class="title"><ICountUp :endVal="totals.game_duration / 60 / 60" /> hours</p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Total FF Damage</p>
                <p class="title"><ICountUp :endVal="totals.survivor_ff" /> HP</p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Zombies Killed</p>
                <p class="title"><ICountUp :endVal="totals.zombie_kills" /></p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Unique Players</p>
                <p class="title"><ICountUp :endVal="totals.total_users" /></p>
                </div>
            </div>
        </nav>
        <SummaryBit :values="totals" />
        <hr>
        <p class="title is-6">Averages</p>
        <nav class="level">
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Average Game Duration</p>
                <p class="title"><ICountUp :endVal="averages.game_duration / 60" /> min</p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Average Zombies Killed</p>
                <p class="title"><ICountUp :endVal="averages.zombie_kills" /></p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Players per Game</p>
                <p class="title"><ICountUp :endVal="averages.avgPlayers" /></p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Average FF Damage</p>
                <p class="title"><ICountUp :endVal="averages.survivor_ff" /> HP</p>
                </div>
            </div>
            <div class="level-item has-text-centered">
                <div>
                <p class="heading">Average Ping</p>
                <p class="title"><ICountUp :endVal="averages.ping" /> ms</p>
                </div>
            </div>
        </nav>
        <SummaryBit :values="averages" />
        <hr>
        <div class="columns has-text-centered">
            <div class="column">
                <p class="title is-6">Most Played Official Map</p>
                <figure class="image is-4by3">
                    <img :src="mostPlayedCampaignImage">
                </figure>
                <p class="is-family-sans-serif is-size-4">{{getMapName(averages.top_map)}}</p>
            </div>
            <div class="column">
                <p class="title is-6">Least Played Official Map</p>
                <figure class="image is-4by3">
                    <img :src="leastPlayedCampaignImage">
                </figure>
                <p class="is-family-sans-serif is-size-4">{{getMapName(averages.least_map)}}</p>
            </div>
        </div>
        <span class='has-text-centered'>
          <p><b>Most Played Difficulty:</b></p>
          <p>{{ mostPlayedDifficulty }}</p>
        </span>
    </div>
    <br><br>
</div>
</template>
<script>
import { getMapImage, getMapName } from '../js/map'
import SummaryBit from '../components/SummaryBit';
import ICountUp from 'vue-countup-v2';
import GameInfo from '../assets/gameinfo.json'
export default {
    data() {
        return {
            loading: true,
            averages: null,
            totals: null
        }
    },
    components: {
        SummaryBit,
        ICountUp
    },
    mounted() {
        Promise.all([
            this.fetchAverage(),
            this.fetchTotal()
        ]).finally(() => this.loading = false)
    },
    computed: {
        mostPlayedDifficulty() {
            if(!this.averages) return null;
            return GameInfo.difficulties[Number(this.averages.difficulty)]
        },
        mostPlayedCampaignImage() {
            return getMapImage(this.averages.top_map)
        },
        leastPlayedCampaignImage() {
            return getMapImage(this.averages.least_map)
        }
    },
    methods: {
        getMapName,
        fetchAverage() {
            this.loading = true;
            this.$http.get(`/api/summary`, { cache: true })
            .then(r => {
                this.averages = {
                    top_map: r.data.topMap,
                    least_map: r.data.bottomMap,
                    avgPlayers: r.data.averagePlayers,
                    ...r.data.stats
                }
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch average values',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchAverage()
                })
            })
        },
        fetchTotal() {
            this.loading = true;
            this.$http.get(`/api/totals`, { cache: true })
            .then(r => {
                this.totals = r.data.stats

            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch total values',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchTotal()
                })
            })
        },
        formatNumber(number) {
            if(!number) return 0;
            return Math.round(number).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
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

<style>
img {
    object-fit: contain;
}
</style>
