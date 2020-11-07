<template>
<div>
    <section class="hero is-dark">
        <div v-if="session" class="hero-body">
            <div class="container">
            <h1 class="title">
                Session #{{session.id}}
            </h1>
            <p class="subtitle is-4">{{session.last_alias}} - {{session.points | formatNumber}} points</p>
            </div>
        </div>
        <div v-else class="hero-body">
            <div class="container">
            <h1 class="title">
                Session #{{$route.params.id}}
            </h1>
            <p class="subtitle is-4">Not Found</p>
            </div>
        </div>
    </section>
    <br>
    <div v-if="session" class="container is-fluid">
        <div class="columns">
            <div class="column is-8">
                <article class="message is-warning has-text-left">
                <div class="message-body">
                    This page is very much a work in progress. Only the basic information is given, a better UI will be implemented later.
                </div>
                </article>
            </div>
        </div>
        <div class="columns">
            <div class="column">
                <table class="table">
                    <thead>
                        <tr>
                            <td>Molotovs</td>
                            <td>Pipebombs</td>
                            <td>Boomer Biles</td>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>{{session.MolotovsUsed}}</td>
                            <td>{{session.PipebombsUsed}}</td>
                            <td>{{session.BoomerBilesUsed}}</td>
                        </tr>
                    </tbody>
                </table>
                <table class="table">
                    <thead>
                        <tr>
                            <td>Pills</td>
                            <td>Adrenalines</td>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>{{session.PillsUsed}}</td>
                            <td>{{session.AdrenalinesUsed}}</td>
                        </tr>
                    </tbody>
                </table>
                <table class="table">
                    <thead>
                        <tr>
                            <td>Kits Used (Total)</td>
                            <td>Kits Used (Shared)</td>
                            <td>Kits Used (Self)</td>
                            <td>Defibs Used</td>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>{{session.MedkitsUsed}}</td>
                            <td>{{session.FirstAidShared}}</td>
                            <td>{{session.MedkitsUsed - session.FirstAidShared}}</td>
                            <td>{{session.DefibrillatorsUsed}}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div class="column">
                <table class="table">
                    <thead>
                        <tr>
                            <td>Damage Taken</td>
                            <td>Friendly Fire Damage</td>
                            <td>Zombies Killed</td>
                            <td>Melee Kills</td>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>{{session.DamageTaken | formatNumber}}</td>
                            <td>{{session.survivorDamage}}</td>
                            <td>{{session.ZombieKills | formatNumber}}</td>
                            <td>{{session.MeleeKills  | formatNumber}}</td>
                        </tr>
                    </tbody>
                </table>
                <table class="table">
                    <thead>
                        <tr>
                            <td>Incaps</td>
                            <td>Deaths</td>
                            <td>Revived Others</td>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>{{session.Incaps}}</td>
                            <td>{{session.Deaths}}</td>
                            <td>{{session.ReviveOtherCount}}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div class="column is-3">
                <div class="box">
                    <h5 class="title is-5">Players</h5>
                    <span class="has-text-left" v-if="users.length > 0">
                        <div v-for="userRecord in users" :key="userRecord.steamid">
                            <div>
                                <div class="has-text-left is-inline-block">
                                    <router-link v-if="session.steamid != userRecord.steamid" :to="'/user/' + userRecord.steamid">{{userRecord.last_alias}}</router-link>
                                    <p v-else>{{userRecord.last_alias}}</p>
                                </div>
                                <div class="is-pulled-right is-inline">
                                    <router-link v-if="session.steamid != userRecord.steamid" :to="'/sessions/details/' + userRecord.id">(view stats)</router-link>
                                </div>
                            </div>
                        </div>
                    </span>
                    <span v-else>
                        No other users were recorded.
                    </span>
                </div>
                <div class="box">
                    <h6 class="title is-6">Meta Information</h6>
                    <div class="has-text-left">
                        <strong>Map</strong>
                        <p>{{getMap(session.map)}}<p>
                        <strong>Gamemode</strong>
                        <p>{{getGamemode(session.gamemode)}}</p>
                        <strong>Difficulty</strong>
                        <p>{{getDifficulty(session.difficulty)}}</p>
                        <strong>Date Played</strong>
                        <p>{{formatDate(session.date_end*1000)}}</p>
                        <br>
                        <em>Campaign ID</em><br>
                        <em>{{session.campaignID}}</em>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import { getMapNameByChapter} from '../js/map'
export default {
    data() {
        return {
            session: null,
            users: [],
            loading: true
        }
    },
    mounted() {
        this.getSession()
    },
    computed: {
        players() {
            if(!this.session.players) return []
            const users = this.session.players.split(";");
            users.pop();
            return users;
        }
    },
    watch: {
        '$route.params.id': 'getSession'
    },
    methods: {
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
        formatDate(inp) {
            if(inp <= 0 || isNaN(inp)) return ""
            try {
                const date = new Date(inp).toLocaleString()
                return date;
            }catch(err) {
                return "Unknown"
            }
        },
        getMap(str) {
            return getMapNameByChapter(str);
        },
        getSession() {
            if(!this.$route.params.id) return;
            this.loading = true;
            this.$http.get(`/api/sessions/${this.$route.params.id}`, { cache: true })
            .then(r => {
                this.session = r.data.session;
                this.users = r.data.users
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch session information.',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchSessions()
                })
            })
            .finally(() => this.loading = false)
        }
    }
}
</script>
