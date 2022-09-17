<template>
<div>
    <section class="hero is-dark">
        <div v-if="session" class="hero-body">
            <div class="container">
                <div class="columns">
                    <div class="column">
                        <b-button tag="router-link" :to="'/sessions/details/' + (session.id - 1)" icon-left="chevron-circle-left" type="is-dark" size="is-large" />
                    </div>
                    <div class="column">
                        <h1 class="title">
                            Session #{{session.id}}
                        </h1>
                        <p class="subtitle is-4">{{session.last_alias}} - {{session.points | formatNumber}} points</p>
                    </div>
                    <div class="column">
                        <b-button tag="router-link" :to="'/sessions/details/' + (session.id + 1)" icon-left="chevron-circle-right" type="is-dark" size="is-large" />
                    </div>
                </div>
            </div>
        </div>
        <div v-else class="hero-body">
            <div class="container">
                <div class="columns">
                    <div class="column" >
                        <b-button v-if="sessionIdNumber > 0" tag="router-link" :to="'/sessions/details/' + (sessionIdNumber - 1)" icon-left="chevron-circle-left" type="is-dark" size="is-large" />
                    </div>
                    <div class="column">
                        <h1 class="title">
                            Session #{{$route.params.id}}
                        </h1>
                        <p class="subtitle is-4">Not Found</p>
                    </div>
                    <div class="column">
                        <b-button v-if="sessionIdNumber > 0" tag="router-link" :to="'/sessions/details/' + (sessionIdNumber + 1)" icon-left="chevron-circle-right" type="is-dark" size="is-large" />
                    </div>
                </div>
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
                        <p class="heading">Melee Kills</p>
                        <p class="title">{{session.MeleeKills}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Damage Dealt</p>
                        <p class="title">{{session.SurvivorDamage | formatNumber}} HP</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Friendly Fires</p>
                        <p class="title">{{session.SurvivorFFCount}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered" v-if="session.SurvivorFFDamage">
                        <div>
                        <p class="heading">Friendly Damage</p>
                        <p class="title">{{session.SurvivorFFDamage}} HP</p>
                        </div>
                    </div>
                    <template v-if="session.SurvivorFFTakenCount">
                      <div class="level-item has-text-centered">
                          <div>
                          <p class="heading">Times Friendly Fired</p>
                          <p class="title">{{session.SurvivorFFTakenCount || 0}}</p>
                          </div>
                      </div>
                      <div class="level-item has-text-centered">
                          <div>
                          <p class="heading">Friendly Damage Taken</p>
                          <p class="title">{{session.SurvivorFFTakenDamage}} HP</p>
                          </div>
                      </div>
                    </template>
                </nav>
                <div class="tile is-ancestor">
                    <div class="tile is-vertical">
                        <div class="tile">
                            <div class="tile is-parent is-vertical">
                                <article class="tile is-child notification is-info">
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
                                    <PieChart :chart-data="specialKills" />
                                </article>
                            </div>
                            <div class="tile is-parent is-vertical">

                                <article class="tile is-child notification is-warning">
                                    <p class="title is-5">Usages</p>
                                    <p>&nbsp;</p>
                                    <BarChart :chart-data="usages" />
                                </article>

                                <article class="tile is-child notification has-text-white" style="background-color: #d6405e">
                                    <nav class="level">
                                      <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Damage Taken</p>
                                            <p class="title">{{session.DamageTaken}} HP</p>
                                            </div>
                                        </div>
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
                    <h5 class="title is-5 has-text-centered">Players</h5>
                    <span class="has-text-left" v-if="users.length > 0">
                        <div v-for="userRecord in users" :key="userRecord.steamid">
                            <div>
                                <div class="has-text-left is-inline-block">
                                  <b-tooltip label="Click to view their profile" position="is-left">
                                    <router-link  :to="'/user/' + userRecord.steamid"><b>{{userRecord.last_alias}}</b></router-link>
                                  </b-tooltip>
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
                    <div class="has-text-left">
                        <strong>Map</strong>
                        <p>{{mapTitle}} <em class="is-pulled-right">({{session.map}})</em></p>
                        <div>
                          <span class="is-inline-block">
                          <strong>Gamemode</strong>
                          <p>{{getGamemode(session.gamemode)}}</p>
                          </span>
                          <span class="is-pulled-right">
                            <strong>Difficulty</strong>
                            <p>{{getDifficulty(session.difficulty)}}</p>
                          </span>
                        </div>
                        <strong>Date Played</strong>
                        <p>{{formatDate(session.date_end*1000)}}</p>
                        <span v-if="session.date_start">
                            <strong>Game Duration</strong>
                            <p>{{secondsToHms((session.date_end-session.date_start))}}</p>
                        </span>
                        <span v-if="session.ping > 0">
                          <strong>Average Ping</strong>
                          <p>{{session.ping}} ms</p>
                        </span>
                        <strong>Most Used Weapon</strong>
                        <p>{{topWeaponName}}</p>
                        <span v-if="session.minutes_idle > 0">
                          <strong>Minutes Idle</strong>
                          <p>{{session.minutes_idle}} minute{{session.minutes_idle > 1 ? 's' : ''}} ({{idlePercentage}}%)</p>
                        </span>
                        <span v-if="session.server_tags">
                            <br>
                            <b-taglist v-if="session.server_tags">
                                <b-tag v-for="tag in session.server_tags.split(',')" :key="tag" :class="getTagType(tag)">
                                    {{tag}}
                                </b-tag>
                            </b-taglist>
                        </span>
                    </div>
                </div>
                <em>Campaign ID</em><br>
                <em><router-link :to="campaignURL"> {{session.campaignID}}</router-link></em>
            </div>
        </div>
        <nav class="level">
          <div class="level-item has-text-centered">
              <div>
              <p class="heading">Times Boomed</p>
              <p class="title">{{session.TimesBoomed}}</p>
              </div>
          </div>
          <div class="level-item has-text-centered">
              <div>
              <p class="heading">Teammates Boomed</p>
              <p class="title">{{session.BoomedTeammates}}</p>
              </div>
          </div>
          <div class="level-item has-text-centered">
              <div>
              <p class="heading">Car Alarms Activated</p>
              <p class="title">{{session.CarAlarmsActivated}}</p>
              </div>
          </div>
          <div class="level-item has-text-centered">
              <div>
              <p class="heading">Times Saved Pinned</p>
              <p class="title">{{session.ClearedPinned}}</p>
              </div>
          </div>
          <div class="level-item has-text-centered">
              <div>
              <p class="heading">Rocks Hitby</p>
              <p class="title">{{session.RocksHitBy}}</p>
              </div>
          </div>
          <div class="level-item has-text-centered">
              <div>
              <p class="heading">Rocks Dodged</p>
              <p class="title">{{session.RocksDodged}}</p>
              </div>
          </div>
      </nav>
      <nav class="level">
        <div class="level-item has-text-centered">
          <div>
            <p class="heading">Damage to Tank</p>
            <p class="title">{{session.DamageToTank | formatNumber}} HP</p>
          </div>
        </div>
        <div class="level-item has-text-centered">
          <div>
            <p class="heading">Damage to Witch</p>
            <p class="title">{{session.DamageToWitch | formatNumber}} HP</p>
          </div>
        </div>
        <div class="level-item has-text-centered">
          <div>
            <p class="heading">Witches Crowned</p>
            <p class="title">{{session.WitchesCrowned}}</p>
          </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Clowns Honked</p>
            <p class="title">{{session.honks}}</p>
            </div>
        </div>
      </nav>
      <br>
    </div>
</div>
</template>

<script>
import GameInfo from '@/assets/gameinfo.json'

import { getMapName } from '../js/map'
import {PieChart, BarChart, getChartData } from '../js/graphs.js'
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
        idlePercentage() {
          const gameLength = this.session.date_end - this.session.date_start;
          if(gameLength > 60)
            return Math.round(this.session.minutes_idle / (gameLength / 60) * 10000) / 100
          else return "0"
        },
        sessionIdNumber() {
            return parseInt(this.$route.params.id);
        },
        specialKills() {
            if(!this.session) return []
            return getChartData('Special Kills',[
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
            ])
        },
        usages() {
            if(!this.session) return []
            return getChartData('Uses', [
                {
                    label: 'Pills',
                    value: this.session.PillsUsed
                },
                {
                    label: 'Adrenalines',
                    value: this.session.AdrenalinesUsed
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
            ], '#62a4b4');
        },
        mapTitle() {
            return this.session.map ? getMapName(this.session.map) : null
        },
        mapId() {
            const title = this.mapTitle;
            return title ? title.toLowerCase().replace(/\s/, '-') : null
        },
        campaignURL() {
            return this.session && this.session.campaignID ?
                `/campaigns/${this.session.campaignID.substring(0,8)}` : '#'
        },
        topWeaponName() {
          if(!this.session.top_weapon) return null
          let weapon = GameInfo.weapons[this.session.top_weapon.slice(7)]
          if(weapon) return `${weapon} (${this.session.top_weapon})`
          return this.session.top_weapon
        }
    },
    methods: {
        getTagType(tag) {
            switch(tag.toLowerCase()) {
                case "dev": return 'is-danger'
                case "prod": return "is-success"
                case "old": return "is-warning"
                case "improved": return "is-dark"
                default: return ''
            }
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
        formatDate(inp) {
            if(inp <= 0 || isNaN(inp)) return ""
            try {
                const date = new Date(inp).toLocaleString()
                return date;
            }catch(err) {
                return "Unknown"
            }
        },
        getSession() {
            if(!this.$route.params.id) return;
            if(this.$route.name !== "SessionDetail") return;

            this.loading = true;
            this.$http.get(`/api/sessions/${this.$route.params.id}`, { cache: true })
            .then(r => {
                this.session = r.data.session;
                this.users = r.data.users
                document.title = `Session #${this.session.id} - ${this.session.last_alias} - L4D2 Stats Plugin`
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

            var hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
            var mDisplay = m > 0 ? m + (m == 1 ? " minute, " : " minutes ") : "";

            return hDisplay + mDisplay
        }
    }
}
</script>
