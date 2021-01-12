<template>
<div>
    <section class="hero is-dark">
        <div v-if="sessions.length > 0" class="hero-body">
            <div class="container">
                <div class="columns">
                    <div class="column">
                        <h1 class="title">
                            Campaign {{$route.params.id.substring(0,8)}}
                        </h1>
                        <p class="subtitle is-4">Played {{formatDate(sessions[0].date_end*1000)}}</p>
                        <hr>
                        <p class="is-size-4">
                            {{mapTitle}} • {{getGamemode(sessions[0].gamemode)}} • {{getDifficulty(sessions[0].difficulty)}} 
                        </p>
                    </div>
                </div>
            </div>
        </div>
        <div v-else class="hero-body">
            <div class="container">
                <div class="columns">
                    <div class="column">
                        <h1 class="title">
                            Campaign Not Found
                        </h1>
                    </div>
                </div>
            </div>
        </div>
    </section>
    <div class="container is-fluid">
        <br>
        <h4 class="title is-4">Players</h4>
        <div class="columns is-multiline">
            <div v-for="session in sessions" class="column is-3" :key="session.id">
                <div class="box">
                    <img class="is-inline-block is-pulled-left image is-128x128" :src="'/img/portraits/' + getCharacterName(session.characterType) + '.png'" />
                    <h6 class="title is-6">{{session.last_alias.substring(0,20)}}</h6>
                    <p class="subtitle is-6">{{session.points | formatNumber}} points</p>
                    <hr class="player-divider">
                    <ul class="has-text-right">
                        <li><span class="has-text-info">{{session.ZombieKills}}</span> commons killed</li>
                        <li><span class="has-text-info">{{getSpecialKills(session)}}</span>  specials killed</li>
                        <li><span class="has-text-info">{{session.SurvivorDamage}}</span>  friendly fire HP dealt</li>
                    </ul>
                    <br>
                    <b-button type="is-info" tag="router-link" :to="'/sessions/details/' + session.id" expanded>View Details</b-button>
                </div>
            </div> 
        </div>
    </div>
    <hr>
    <h4 class="title is-4">Statistics</h4>

    <br>
</div>
</template>

<script>
import { getMapName } from '@/js/map'
export default {
    data() {
        return {
            loading: true,
            sessions: [],
            totals: []
        }
    },
    watch: {
        '$route.params.id': 'fetchDetails()'
    },
    mounted() {
        this.fetchDetails()
    },
    computed: {
        mapTitle() {
            return this.sessions.length > 0 ? getMapName(this.sessions[0].map) : null;
        },
    },
    methods: {
        fetchDetails() {
            this.loading = true;
            this.$http.get(`/api/campaigns/${this.$route.params.id}`)
            .then(r => {
                this.sessions = r.data;
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch campaign session details',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchDetails()
                })
            })
            .finally(() => this.loading = false)
        },
        formatDate(inp) {
            if(inp <= 0 || isNaN(inp)) return ""
            try {
                const date = new Date(inp)
                return `${date.toLocaleDateString()} at ${date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
            }catch(err) {
                console.log(err)
                return "Unknown"
            }
        },
        getSpecialKills(session) {
            return session.boomer_kills + session.spitter_kills + session.jockey_kills + session.charger_kills + session.hunter_kills + session.smoker_kills;
        },
        getDifficulty(inp) {
            switch(inp) {
                case 0: return "Easy"
                case 1: return "Normal"
                case 2: return "Advanced"
                case 3: return "Expert"
            }
        },
        getGamemode(inp) {
            switch(inp) {
                case "coop": return "Campaign"
                case "tankrun": return "TankRun"
                case "rocketdude": return "RocketDude"
                default: {
                    return inp[0].toUpperCase() + inp.slice(1)
                }
            }
        },
        getCharacterName(number) {
            switch(number) {
                case 0: return "gambler";
                case 1: return "producer"
                case 2: return "mechanic"
                case 3: return "coach"
                case 4: return "namvet"
                case 5: return "zoey"
                case 6: return "biker"
                case 7: return "manager"
                default: return "random"
            }
        }
    }
}
</script>

<style>
.player-divider {
    margin: 0.5rem 0;
}
</style>