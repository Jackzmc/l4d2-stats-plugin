<template>
<div class="has-text-white" style="background-color: #4c516d">
    <section class="hero is-dark" >
        <div class="hero-body">
            <div class="container ">
                <div class="columns">
                    <div v-if="$route.params.id && sessions.length > 0 && !loading" class="column">
                        <h1 class="title">
                            {{mapTitle}}
                            <a v-if="$SHARE_URL" style="color: white" @click="getShareLink()"><b-icon icon="share" /></a>
                        </h1>
                        <p class="subtitle is-4">Played {{formatDate(sessions[0].date_end*1000)}}</p>
                        <hr>
                        <p class="is-size-4">
                            {{getGamemode(sessions[0].gamemode)}} • {{getDifficulty(sessions[0].difficulty)}} • {{secondsToHms(sessions[0].date_end-sessions[0].date_start)}} long
                        </p>
                    </div>
                    <div v-else-if="!loading" class="column">
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
        <div class="columns is-multiline">
            <div v-for="(session) in sessions" class="column is-3" :key="session.id">
                <div :class="[{'bg-mvp': mvp === session.steamid}, 'box', 'has-text-centered']" style="position: relative">
                    <router-link :to="'/user/' + session.steamid"><img class="is-inline-block is-pulled-left image is-128x128" :src="'/img/portraits/' + getCharacterName(session.characterType) + '.png'" /></router-link>
                    <h6 class="title is-6">
                        <router-link :to="'/user/' + session.steamid" class="has-text-info">
                            {{session.last_alias.substring(0,20)}}
                        </router-link>
                    </h6>
                    <!-- TODO: Show a on hover description of MVP. Left side describes point breakdown, right shows values (3x3, etc) -->
                    <p class="subtitle is-6">{{session.points | formatNumber}} points</p>
                    <hr class="player-divider">
                    <ul class="has-text-right">
                        <li><span class="has-text-info">{{session.ZombieKills}}</span> commons killed</li>
                        <li><span class="has-text-info">{{session.SpecialInfectedKills}}</span>  specials killed</li>
                        <li>
                            <span :class="['has-text-info',{'has-text-weight-bold': isMostFF(session)}]">
                              {{session.SurvivorDamage}}
                            </span>
                            friendly fire damage
                        </li>
                        <li v-if="totals.honks > 0"><span class="has-text-info">{{session.honks}}</span>  clown honks</li>
                    </ul>
                    <br>
                    <b-button type="is-info" tag="router-link" :to="'/sessions/details/' + session.id" expanded>View Details</b-button>
                    <div v-if="isMVP(session)" class="ribbon ribbon-top-left"><span>MVP</span></div>
                    <div v-if="isHonkMaster(session)" class="ribbon ribbon-top-left ribbon-honk"><span>Honk Master</span></div>
                </div>
            </div>
        </div>
    </div>
    <hr>
    <div v-if="totals" class="container is-fluid">
        <div class="columns">
            <div class="column">
                <nav class="level">
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Zombies Killed</p>
                        <p class="title has-text-white">{{totals.ZombieKills}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Specials Killed</p>
                        <p class="title has-text-white">{{totals.SpecialInfectedKills}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Damage Taken</p>
                        <p class="title has-text-white">{{totals.DamageTaken}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Melee Kills</p>
                        <p class="title has-text-white">{{totals.MeleeKills}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                        <p class="heading">Friendly Fire Damage Dealt</p>
                        <p class="title has-text-white">{{totals.SurvivorDamage}}</p>
                        </div>
                    </div>
                </nav>
                <div class="tile is-ancestor">
                    <div class="tile is-vertical">
                        <div class="tile">
                            <div class="tile is-parent is-vertical">
                                <article class="tile is-child notification is-info">
                                    <p>&nbsp;</p>
                                    <nav class="level">
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Molotovs</p>
                                            <p class="title">{{totals.MolotovsUsed}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Pipebombs</p>
                                            <p class="title">{{totals.PipebombsUsed}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Biles</p>
                                            <p class="title">{{totals.BoomerBilesUsed}}</p>
                                            </div>
                                        </div>
                                    </nav>
                                </article>
                            </div>
                            <div class="tile is-parent is-vertical">
                                <article class="tile is-child notification has-text-white" style="background-color: #d6405e">
                                    <p>&nbsp;</p>
                                    <nav class="level">
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Incaps</p>
                                            <p class="title">{{totals.Incaps}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Deaths</p>
                                            <p class="title">{{totals.Deaths}}</p>
                                            </div>
                                        </div>
                                        <div class="level-item has-text-centered">
                                            <div>
                                            <p class="heading">Kits Used</p>
                                            <p class="title">{{totals.MedkitsUsed}}</p>
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
                    <div class="has-text-left">
                        <strong>Map</strong>
                        <p>{{mapTitle}} <em class="is-pulled-right">({{sessions[0].map}})</em></p>
                        <strong>Date Played</strong>
                        <p>{{formatDate(sessions[0].date_end*1000)}}</p>
                        <span v-if="isVersusGame">
                          <strong>Versus Second Round?</strong>
                          <p>{{sessions[0].flags & 1 == 1 ? 'Yes' : 'No'}}</p>
                        </span>
                        <span v-if="averagePing > 0">
                          <strong>Average Ping</strong>
                          <p>{{averagePing}} ms</p>
                        </span>
                        <span v-if="totals.honks > 0">
                          <strong>Total Honks</strong>
                          <p>{{totals.honks | formatNumber}}</p>
                        </span>
                        <span v-if="sessions[0].server_tags">
                            <br>
                            <b-taglist v-if="sessions[0].server_tags">
                                <b-tag v-for="tag in sessions[0].server_tags.split(',')" :key="tag" :class="getTagType(tag)">
                                    {{tag}}
                                </b-tag>
                            </b-taglist>
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- TODO: Add more campaign details.
    <hr>
    -->
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
            totals: null,
            mvp: null
        }
    },
    watch: {
        '$route.params.id': 'fetchDetails'
    },
    mounted() {
        this.fetchDetails()
    },
    computed: {
      isVersusGame() {
        if(this.sessions.length == 0) return false;
        const gamemode = this.sessions[0].gamemode;
        return gamemode === "versus" || gamemode === "scavenge"
      },
      mapTitle() {
          return this.sessions.length > 0 ? getMapName(this.sessions[0].map) : null;
      },
      highestHonkCount() {
        if(this.totals.honks > 0) {
          let honkCount = 0, honkID = -1;
          this.sessions.forEach(({honks, steamid}) => {
            if(honkCount < honks || honkID == -1) {
              honkID = steamid
              honkCount = honks
            }
          })
          return honkCount
        }
        return null;
      },
      averagePing() {
        let pingSum = 0;
        this.sessions.forEach(({ping}) => pingSum += ping)
        return Math.round(pingSum / this.sessions.length)
      },
      mostFF() {
        let ffCount = 0, id = -1;
        this.sessions.forEach(({SurvivorDamage, steamid}) => {
          if(SurvivorDamage > ffCount || steamid == -1 ) {
            id = steamid
            ffCount = SurvivorDamage
          }
        })
        return id;
      }
    },
    methods: {
        isMVP(session) {
          return this.mvp === session.steamid
        },
        isHonkMaster(session) {
          if(this.mvp === session.steamid) return false;
          return this.highestHonkCount === session.honks
        },
        isMostFF(session) {
          return this.mostFF === session.steamid
        },
        fetchDetails() {
            if(!this.$route.params.id) return;
            if(this.$route.name !== "Campaign") return;

            this.loading = true;
            this.$http.get(`/api/campaigns/${this.$route.params.id}`)
            .then(r => {
                this.mvp = r.data[0].steamid;
                this.sessions = r.data.sort((a,b) => b.points - a.points);
                this.totals = r.data.reduce((pv, cv) => {
                    return {
                        ZombieKills: pv.ZombieKills + cv.ZombieKills,
                        SurvivorDamage: pv.SurvivorDamage + cv.SurvivorDamage,
                        Deaths: pv.Deaths + cv.Deaths,
                        DamageTaken: pv.DamageTaken + cv.DamageTaken,
                        MeleeKills: pv.MeleeKills + cv.MeleeKills,
                        Incaps: pv.Incaps + cv.Incaps,
                        MolotovsUsed: pv.MolotovsUsed + cv.MolotovsUsed,
                        PipebombsUsed: pv.PipebombsUsed + cv.PipebombsUsed,
                        BoomerBilesUsed: pv.BoomerBilesUsed + cv.BoomerBilesUsed,
                        MedkitsUsed: pv.MedkitsUsed + cv.MedkitsUsed + cv.FirstAidShared,
                        honks: pv.honks + cv.honks,
                        SpecialInfectedKills: pv.SpecialInfectedKills + cv.SpecialInfectedKills
                    }
                });
                document.title = `${this.mapTitle} Campaign - ${this.$route.params.id} - L4D2 Stats Plugin`
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
                case 5: return "teenangst"
                case 6: return "biker"
                case 7: return "manager"
                default: return "random"
            }
        },
        secondsToHms(d) {
            d = Number(d);
            const h = Math.floor(d / 3600);
            const m = Math.floor(d % 3600 / 60);
            //const s = Math.floor(d % 3600 % 60);

            const hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
            const mDisplay = m > 0 ? m + (m == 1 ? " minute " : " minutes ") : "";
            //const sDisplay = s > 0 ? s + (s == 1 ? " second" : " seconds") : "";
            return hDisplay + mDisplay;
        },
        getTagType(tag) {
            switch(tag.toLowerCase()) {
                case "dev": return 'is-danger'
                case "main": return "is-success"
                case "old": return "is-warning"
                case "vanilla+": return "is-dark"
                default: return ''
            }
        },
        getShareLink() {
            const url = `${this.$SHARE_URL}${this.$route.params.id.substring(0,8)}`
            this.$buefy.dialog.alert({
                title: 'Campaign Share Link',
                message: `<a href="${url}">${url}</a>`,
                confirmText: 'OK'
            })
        }
    }
}
</script>

<style>
.player-divider {
    margin: 0.5rem 0;
}
.bg-mvp {
  background-color: rgb(132, 218, 230) !important;
}
.ribbon-honk::before,
.ribbon-honk::after {
  border: 5px solid #a025d1;
}
.ribbon-honk span {
  background-color: #a025d1;
}

@import url('../../css/ribbon.css')
</style>
