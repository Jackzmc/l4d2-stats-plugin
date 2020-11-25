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
            <div class="column">
                <nav class="level">
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Zombies Killed</p>
                        <p class="title">{{session.ZombieKills}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Damage Taken</p>
                        <p class="title">{{session.DamageTaken}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Melee Kills</p>
                        <p class="title">{{session.MeleeKills}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Friendly Fire Damage Dealt</p>
                        <p class="title">{{session.SurvivorDamage}}</p>
                        </div>
                    </div>
                </nav>
                <div class="tile is-ancestor">
                    <div class="tile is-vertical">
                        <div class="tile">
                            <div class="tile is-parent is-vertical">
                                <article class="tile is-child notification is-info">
                                    <p class="title is-4">Throwables</p>
                                    <p>&nbsp;</p>
                                    <nav class="level">
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Molotovs</p>
                                            <p class="title">{{session.MolotovsUsed}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Pipebombs</p>
                                            <p class="title">{{session.PipebombsUsed}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Biles</p>
                                            <p class="title">{{session.BoomerBilesUsed}}</p>
                                            </div>
                                        </div>
                                    </nav>
                                </article>
                                <article class="tile is-child notification is-success">
                                    <p class="title is-4">Specials Killed</p>
                                    <PieChart label="Special Kills" :data="specialKills" />
                                </article>
                            </div>
                            <div class="tile is-parent is-vertical">
                                <article class="tile is-child notification is-warning">
                                    <p class="title is-4">Usages</p>
                                    <p>&nbsp;</p>
                                    <BarChart label="Uses" :data="usages" color="#62a4b4" />
                                </article>
                                <article class="tile is-child notification" style="background-color: #d6405e">
                                    <p class="title is-4">Misc</p>
                                    <p>&nbsp;</p>
                                    <nav class="level">
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Incaps</p>
                                            <p class="title">{{session.Incaps}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Deaths</p>
                                            <p class="title">{{session.Deaths}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Revives (others)</p>
                                            <p class="title">{{session.ReviveOtherCount}}</p>
                                            </div>
                                        </div>
                                    </nav>
                                </article>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="column is-3">
                <div class="box">
                    <h5 class="title is-5">Players</h5>
                    <span class="has-text-left" v-if="users.length > 0">
                        <div v-for="userRecord in users" :key="userRecord.steamid">
                            <div>
                                <div class="has-text-left is-inline-block">
                                    <router-link v-if="session.steamid != userRecord.steamid" :to="'/user/' + userRecord.steamid"><b>{{userRecord.last_alias}}</b></router-link>
                                    <p v-else><b>{{userRecord.last_alias}}</b></p>
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
                        <span v-if="session.date_start">
                            <strong>Game Duration</strong>
                            <p>{{secondsToHms((session.date_end-session.date_start))}}</p>
                        </span>
                        <strong>Average Ping</strong>
                        <p>{{session.ping}} ms</p>
                    </div>
                </div>
                <em>Campaign ID</em><br>
                <em>{{session.campaignID}}</em>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import { getMapNameByChapter} from '../js/map'
import {PieChart, BarChart } from '../js/graphs.js'
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
    watch: {
        '$route.params.id': 'getSession'
    },
    components: {
        PieChart,
        BarChart
    },
    computed: {
        specialKills() {
            if(!this.session) return []
            return [
                {
                    label: 'Boomer',
                    color: '#00529B',
                    value: this.session.boomer_kills
                },
                {
                    label: 'Spitter',
                    color: '#7AC142',
                    value: this.session.spitter_kills
                },
                {
                    label: 'Jockey',
                    color: '#F47A1F',
                    value: this.session.jockey_kills
                },
                {
                    label: 'Charger',
                    color: '#FDBB2F',
                    value: this.session.charger_kills
                },
                {
                    label: 'Smoker',
                    color: '#377B2B',
                    value: this.session.smoker_kills
                },
                {
                    label: 'Hunter',
                    color: '#007CC3',
                    value: this.session.hunter_kills
                }
            ]
        },
        damageValues() {
            if(!this.session) return []
            return [
                [
                    {
                        label: 'Damage Taken',
                        value: this.session.DamageTaken,
                        color: '#62a462'
                    },
                    {
                        label: 'Friendly Fire Damage Dealt',
                        value: this.session.SurvivorDamage,
                        color: '#62a462'
                    },
                ],
                {
                    label: 'Zombies Killed',
                    value: this.session.ZombieKills,
                    color: '#62a462'
                },
                {
                    label: 'Melee Kills',
                    value: this.session.MeleeKills,
                    color: '#62a462'
                }
            ]
        },
        usages() {
            if(!this.session) return []
            return [
                {
                    label: 'Pills',
                    value: this.session.PillsUsed
                },
                {
                    label: 'Adrendaline',
                    value: this.session.AdrendalineUsed
                },
                {
                    label: 'Kits (Self)',
                    value: this.session.MedkitsUsed - this.session.FirstAidShared
                },
                {
                    label: 'Kits (Shared)',
                    value: this.session.FirstAidShared
                },
                {
                    label: 'Defibs',
                    value: this.session.DefibrillatorsUsed
                }
            ]
        }
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
