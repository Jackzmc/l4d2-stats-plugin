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
        <div class="columns is-multiline">
            <div v-for="campaign in recentCampaigns" class="column is-3" :key="campaign.campaignID">
                <div class="box">
                    <img class="is-inline-block is-pulled-left image is-128x128" :src="getMapImage(campaign.map)" />
                    <h6 class="title is-6">{{getMapName(campaign.map).substring(0,20)}}</h6>
                    <p class="subtitle is-6">{{getGamemode(campaign.gamemode)}} • {{formatDifficulty(campaign.difficulty)}}</p>
                    <hr class="player-divider">
                    <ul class="has-text-right">
                        <li><b>{{secondsToHms((campaign.date_end-campaign.date_start))}}</b> long</li>
                        <li><b>{{campaign.Deaths}}</b> deaths</li>
                        <li><b>{{campaign.CommonsKilled | formatNumber}}</b> commons killed</li>
                        <li><b>{{campaign.FF | formatNumber}}</b> friendly fire dealt</li>
                    </ul>
                    <br>
                    <b-button type="is-info" tag="router-link" :to="'/campaigns/' + campaign.campaignID" expanded>View Details</b-button>
                </div>
            </div> 
        </div>
    </div>
    <hr>
    <div class="container">
        <h5 class="title is-5">Top Games Played</h5>
        <b-table 
            :data="topCampaigns"
            :loading="loading"

            paginated 
            backend-pagination 
            :current-page="1" 
            per-page=12
            :total="total_campaigns" 
            @page-change="onPageChange" 

        >
        <!-- TODO: background sort -->
            <template slot-scope="props" >
                <b-table-column label="View">
                    <b-button tag="router-link" :to="'/campaigns/' + props.row.campaignID" expanded>View</b-button>
                </b-table-column>
                <b-table-column field="map" label="Map" >
                    {{ getMapName(props.row.map) }}
                </b-table-column>
                <b-table-column field="CommonsKilled" label="Commons Killed">
                    {{ props.row.CommonsKilled }}
                </b-table-column>
                <b-table-column field="Deaths" label="Total Deaths" >
                    {{ props.row.Deaths }}
                </b-table-column>
                
                <b-table-column field="difficulty" label="Difficulty" centered>
                    {{ formatDifficulty(props.row.difficulty) }}
                </b-table-column>
            </template>
            <template slot="empty">
                <section class="section">
                    <div class="content has-text-grey has-text-centered">
                        <p>There are no recorded campaigns</p>
                    </div>
                </section>
            </template>
        </b-table>
    </div>
</div>
</template>

<script>
import { getMapName, getMapImage } from '@/js/map'
export default {
    data() {
        return {
            recentCampaigns: [],
            topCampaigns: [],
            loading: true,
            total_campaigns: 0
        }
    },
    mounted() {
        /*let routerPage = parseInt(this.$route.params.page);
        if(isNaN(routerPage) || routerPage <= 0) routerPage = 1;
        this.current_page = routerPage;*/
        this.fetchCampaigns()
        document.title = `Campaigns - L4D2 Stats Plugin`
    },
    methods: {
        getMapName,
        getMapImage,
        fetchCampaigns(page = 0) {
            this.loading = true;
            this.$http.get(`/api/campaigns/?page=${page}&perPage=12`, { cache: true })
            .then(r => {
                r.data.recentCampaigns.forEach(v => v.campaignID = v.campaignID.substring(0, 8));
                this.recentCampaigns = r.data.recentCampaigns;
                this.topCampaigns = r.data.topCampaigns;
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
        }
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