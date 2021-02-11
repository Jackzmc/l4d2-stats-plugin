<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
            <h1 class="title">
                Campaigns
            </h1>
            <p class="subtitle is-4">{{total_campaigns | formatNumber}} total campaigns played</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container is-fluid">
        <h5 class="title is-5">Recently Played Games</h5>
        <!-- <b-carousel-list 
            v-if="recentCampaigns.length > 0" 
            v-model="selectedRecent" 
            :data="recentCampaigns" 
            :items-to-show="4"
            :items-to-list="1"
        >
            <template #item="campaign">
                <div class="box">
                    <img class="is-inline-block is-pulled-left image is-128x128" :src="getMapImage(campaign.list.map)" />
                    <h6 class="title is-6">{{getMapName(campaign.list.map).substring(0,20)}}</h6>
                    <p class="subtitle is-6">{{getGamemode(campaign.list.gamemode)}} • {{formatDifficulty(campaign.list.difficulty)}}</p>
                    <hr class="player-divider">
                    <ul class="has-text-right">
                        <li><b>{{secondsToHms((campaign.list.date_end-campaign.list.date_start))}}</b> long</li>
                        <li><b>{{campaign.list.Deaths}}</b> deaths</li>
                        <li><b>{{campaign.list.CommonsKilled | formatNumber}}</b> commons killed</li>
                        <li><b>{{campaign.list.FF | formatNumber}}</b> friendly fire dealt</li>
                    </ul>
                    <br>
                    <b-taglist v-if="campaign.list.server_tags">
                        <b-tag v-for="tag in campaign.list.server_tags.split(',')" :key="tag" :type="getTagType(tag)">
                            {{tag}}
                        </b-tag>
                    </b-taglist>
                    <span v-else><br><br></span>
                    <b-button type="is-info" tag="router-link" :to="'/campaigns/' + campaign.campaignID" expanded>View Details</b-button>
                </div>
            </template>
        </b-carousel-list> -->
        <div class="columns is-multiline">
            <div v-for="campaign in recentCampaigns" class="column is-3" :key="campaign.campaignID">
                <div class="box">
                    <img class="is-inline-block is-pulled-left image is-128x128" :src="getMapImage(campaign.map)" />
                    <h6 class="title is-6">{{getMapName(campaign.map).substring(0,20)}}</h6>
                    <p class="subtitle is-6"><span class="has-text-info">{{getGamemode(campaign.gamemode)}}</span> • <span class="has-text-info">{{formatDifficulty(campaign.difficulty)}}</span></p>
                    <hr class="player-divider">
                    <ul class="has-text-right">
                        <li><b>{{secondsToHms((campaign.date_end-campaign.date_start))}}</b> long</li>
                        <li><b>{{campaign.Deaths}}</b> deaths</li>
                        <li><b>{{campaign.CommonsKilled | formatNumber}}</b> commons killed</li>
                        <li><b>{{campaign.FF | formatNumber}}</b> friendly fire dealt</li>
                    </ul>
                    <br>
                    <b-taglist v-if="campaign.server_tags">
                        <b-tag v-for="tag in parseTags(campaign.server_tags)" :key="tag" :type="getTagType(tag)">
                            {{tag}}
                        </b-tag>
                    </b-taglist>
                    <span v-else><br><br></span>
                    <b-button type="is-info" tag="router-link" :to="'/campaigns/' + campaign.campaignID" expanded>View Details</b-button>
                </div>
            </div> 
        </div>
    </div>
    <hr>
    <div class="container">
        <h5 class="title is-5">Filter Campaigns</h5>
        <span class="has-text-left">
        <b-field grouped>
            <b-field label="Tag Selection">
                <b-select v-model="filtered.filters.tag" placeholder="Select a tag">
                    <option value="prod">All</option>
                    <!-- <option value="dev" v-if="process.env.NODE_ENV !== 'production'">Dev</option> -->
                    <option value="lgs">Improved</option>
                    <option value="public">Public</option>
                    <optgroup label="Regions">
                        <option value="tx">Texas</option>
                    </optgroup>
                    <optgroup label="Server">
                        <option value="server-1">Server TX-P1</option>
                        <option value="server-2">Server TX-P2</option>
                    </optgroup>
                </b-select>
            </b-field>
            <b-field label="Map Type">
                <b-select v-model="filtered.filters.type">
                    <option value="all">Any</option>
                    <option value="official">Official Only</option>
                    <option value="custom">Custom Only</option>
                </b-select>
            </b-field>
            <b-field label="Gamemode">
                <b-select v-model="filtered.filters.gamemode">
                    <option value="all">Any</option>
                    <option value="coop">Coop</option>
                    <option value="versus">Versus</option>
                    <option value="TankRun">Tank Run</option>
                    <option value="RocketDude">RocketDude</option>
                </b-select>
            </b-field>
        </b-field>
        </span>
        <hr>
        <div class="columns is-multiline">
            <div v-for="campaign in filtered.list" class="column is-3" :key="campaign.campaignID">
                <div class="box" style="height: 100%">
                    <h4 class="title is-4">{{getMapName(campaign.map).substring(0,40)}}</h4>
                    <p class="subtitle is-6">
                        <span class="has-text-info">{{getGamemode(campaign.gamemode)}}</span> • <span class="has-text-info">{{formatDifficulty(campaign.difficulty)}}</span>
                        <br>Played <b>{{formatDate(campaign.date_end)}}</b>
                    </p>
                    <p class="subtitle is-6"></p>
                    <hr class="player-divider">
                    <ul class="has-text-left">
                        <li><b>{{secondsToHms((campaign.date_end-campaign.date_start))}}</b> long</li>
                        <li><b>{{campaign.Deaths}}</b> deaths</li>
                        <li><b>{{campaign.CommonsKilled | formatNumber}}</b> commons killed</li>
                        <li><b>{{campaign.FF | formatNumber}}</b> friendly fire dealt</li>
                        <li><b>{{campaign.playerCount}}</b> players</li>
                    </ul>
                    <br>
                    <b-taglist v-if="campaign.server_tags">
                        <b-tag v-for="tag in parseTags(campaign.server_tags)" :key="tag" :type="getTagType(tag)">
                            {{tag}}
                        </b-tag>
                    </b-taglist>
                    <span v-else><br><br></span>
                    <b-button type="is-info" tag="router-link" :to="'/campaigns/' + campaign.campaignID" expanded>View Details</b-button>
                </div>
            </div> 
        </div>
        <br>
    </div>
</div>
</template>

<script>
import { getMapName, getMapImage } from '@/js/map'
export default {
    data() {
        return {
            recentCampaigns: [],
            loading: true,
            total_campaigns: 0,
            selectedRecent: 0,
            filtered: {
                filters: {
                    tag: null,
                    type: "all",
                    gamemode: 'all',
                    page: 0
                },

                list: [],
                loading: true,
            }
        }
    },
    mounted() {
        /*let routerPage = parseInt(this.$route.params.page);
        if(isNaN(routerPage) || routerPage <= 0) routerPage = 1;
        this.current_page = routerPage;*/
        this.fetchCampaigns()
        document.title = `Campaigns - L4D2 Stats Plugin`
    },
    watch: {
        "filtered.filters": {
            handler(e) {
                console.log(e)
                this.fetchFilteredCampaigns()
            },
            deep: true
        }
    },
    methods: {
        getMapName,
        getMapImage,
        fetchFilteredCampaigns() {
            this.filtered.loading = true;
            const queryParams = `?page=${this.filtered.filters.page}&perPage=16&tag=${this.filtered.filters.tag}&gamemode=${this.filtered.filters.gamemode}&type=${this.filtered.filters.type}
            `.replace(/\s/,'')
            this.$http.get(`/api/campaigns${queryParams}`, { cache: true })
            .then(r => {
                r.data.recentCampaigns.forEach(v => v.campaignID = v.campaignID.substring(0, 8));
                this.filtered.list = r.data.recentCampaigns
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch filtered campaigns',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchFilteredCampaigns()
                })
            })
            .finally(() => this.filtered.loading = false)
        },
        fetchCampaigns(page = 0) {
            this.loading = true;
            this.$http.get(`/api/campaigns/?page=${page}&perPage=8`, { cache: true })
            .then(r => {
                r.data.recentCampaigns.forEach(v => v.campaignID = v.campaignID.substring(0, 8));
                this.recentCampaigns = r.data.recentCampaigns;
                this.total_campaigns = r.data.total_campaigns
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch campaigns',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchCampaigns()
                })
            })
            .finally(() => this.loading = false)
        },
        onPageChange(page) {
            this.fetchCampaigns(page);
        },
        getGamemode(inp) {
            switch(inp) {
                case "coop": return "Campaign"
                case "tankrun": return "Tank Run"
                case "rocketdude": return "RocketDude"
                default: {
                    return inp[0].toUpperCase() + inp.slice(1)
                }
            }
        },
        formatDifficulty(difficulty) {
            switch(difficulty) {
                case 0: return "Easy"
                case 1: return "Normal";
                case 2: return "Advanced"
                case 3: return "Expert"
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
                case "prod": return "is-success"
                case "old": return "is-warning"
                case "improved": return "is-dark"
                default: return ''
            }
        },
        parseTags(tags) {
            const arr = tags.split(',')
            if(arr.length > 0 && arr[0] === "prod") return arr.slice(1)
            return arr;
        },
        formatDate(inp) {
            if(inp <= 0 || isNaN(inp)) return ""
            try {
                const date = new Date(inp * 1000).toLocaleString()
                return date;
            }catch(err) {
                return "Unknown"
            }
        },
    }
}

</script>
<style>
.number-cell {
  color: blue;
}
.table td {
    vertical-align: middle;;
}
</style>