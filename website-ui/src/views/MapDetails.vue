<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
            <h1 class="title">
                {{campaignTitle}}
            </h1>
            <p class="subtitle is-4">Played {{totalPlayed}} times</p>
            </div>
        </div>
    </section>
    <br>
    <div v-if="campaign" class="container is-fluid">
        <div class="tile is-ancestor">
            <div class="tile is-vertical">
                <div class="tile">
                    <div class="tile is-parent is-vertical is-4">
                        <article class="tile is-child notification is-info">
                            <p class="title">Best Time</p>
                            <p class="subtitle" v-if="bestSession">{{ secondsToHms(bestSession.duration) }}</p>
                            <p class="subtitle" v-else>N/A</p>
                            <hr>
                            <h6 class="title is-6">Top Player</h6>
                            <p class="subtitle is-4">{{bestSession.last_alias}}</p>
                            <b-button tag="router-link" type="is-secondary" :to="'/user/' + bestSession.steamid">View Profile</b-button>
                        </article>
                        <article class="tile is-child notification is-warning">
                        <p class="title">Statistics</p>
                        <p>{{mapTotals.wins}} Wins</p>
                        <hr>
                        
                        </article>
                    </div>
                    
                    <div class="tile is-parent is-8">
                        <article class="tile is-child ">
                        <figure class="image is-4by3">
                            <img :src="'/img/' + campaign.image">
                        </figure>
                        </article>
                    </div>
                </div>
                
            </div>
            <div class="tile is-parent is-2">
                <article class="tile is-child has-text-left">
                <div class="content">
                    <br>
                    <p class="title">Chapters</p>
                    <div class="content">
                        <ol>
                            <li v-for="chapter in campaign.chapters" :key="chapter">
                                {{chapter}}
                            </li>
                        </ol>
                    </div>
                </div>
                </article>
            </div>
        </div>
    </div>
    <div v-else>
        <b-loading :active="!campaign" />
    </div>
</div>
</template>


<script>
import { CAMPAIGNS } from '../js/map'

export default {
    data() {
        return {
            mapTotals: [],
            bestSession: null,
            campaign: null,
            totalPlayed: 0
        }
    },
    mounted() {
        
        this.fetchDetails();
    },
    watch: {
        '$route.params.map': 'fetchDetails'
    },
    computed: {
        campaignTitle() {
            return this.campaign ? this.campaign.title : this.$route.params.map
        },
    },
    methods: {
        humanReadable(minutes) {
            if(minutes <= 0) return "N/A minutes"
            let hours = Math.floor(minutes / 60);  
            const days = Math.floor(hours / 24);
            minutes = minutes % 60;
            const day_text = days == 1 ? 'day' : 'days'
            const min_text = minutes == 1 ? 'minute' : 'minutes'
            const hour_text = hours == 1 ? 'hour' : 'hours'
            if(days >= 1) {
                hours = hours % 24; 
                return `${days} ${day_text}, ${hours} ${hour_text}`
            }else if(hours >= 1) {
                return `${hours} ${hour_text}, ${minutes} ${min_text}` 
            }else{
                return `${minutes} ${min_text}`
            }
        },
        fetchDetails() {
            for(const chapter in CAMPAIGNS) {
                if(CAMPAIGNS[chapter].id == this.$route.params.map) {
                    this.campaign = CAMPAIGNS[chapter];
                }
            }
            this.finaleChapter = this.campaign.chapters[this.campaign.chapters.length - 1];
            this.$http.get(`/api/maps/${this.finaleChapter}`, { cache: true })
            .then(res => {
                this.mapTotals = res.data.totals
                this.bestSession = res.data.best;
                this.totalPlayed = res.data.total_played
            })
            .catch(err => {
                console.error('Fetch error', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Error ocurred while fetching map information',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchDetails()
                })
            }).finally(() => this.loading = false)
        },
        secondsToHms(d) {
            d = Number(d);
            var h = Math.floor(d / 3600);
            var m = Math.floor(d % 3600 / 60);
            var s = Math.floor(d % 3600 % 60);

            var hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
            var mDisplay = m > 0 ? m + (m == 1 ? " minute, " : " minutes, ") : "";
            var sDisplay = s > 0 ? s + (s == 1 ? " second" : " seconds") : "";
            return hDisplay + mDisplay + sDisplay; 
        }
    }
}
</script>
