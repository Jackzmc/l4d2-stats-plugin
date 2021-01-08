<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
            <h1 class="title">
                Top Played Maps
            </h1>
            </div>
        </div>
    </section>
    <br>
    <div class="container is-fluid">
      <div class="columns">
        <div class="column">
            <b-table :loading="loading" @select="onMapSelect" :data="maps" :selected.sync="selected" @details-open="onDetailsOpen" @details-close="details = null">
                <template slot-scope="props">
                    <b-table-column width="20" >
                        <router-link :to="getCampaignDetailLink(props.row.map_name)"><b-icon icon="angle-right" /></router-link>
                    </b-table-column>
                    <b-table-column field="map_name" label="Map" >
                        <router-link :to="getCampaignDetailLink(props.row.map_name)">
                            <strong>{{ props.row.map_name | formatMap }}</strong>
                        </router-link>
                    </b-table-column>
                    <b-table-column field="wins" label="Wins" centered>
                        {{ props.row.wins | formatNumber }}
                    </b-table-column>
                    <b-table-column field="realism" label="Realism" centered>
                        {{ props.row.realism | formatNumber }}
                    </b-table-column>
                    <b-table-column field="realism" label="Easy" centered>
                        {{ props.row.difficulty_easy | formatNumber }}
                    </b-table-column>
                    <b-table-column field="realism" label="Normal" centered>
                        {{ props.row.difficulty_normal | formatNumber }}
                    </b-table-column>
                    <b-table-column field="realism" label="Advanced" centered>
                        {{ props.row.difficulty_advanced | formatNumber }}
                    </b-table-column>
                    <b-table-column field="realism" label="Expert" centered>
                        {{ props.row.difficulty_expert | formatNumber }}
                    </b-table-column>
                </template>
            </b-table>
        </div>
        <div v-if="selected" class="column is-4">
            <div class="box">
                <router-link :to="getCampaignDetailLink(selected.map_name)">
                <figure class="image is-4by5">
                    <img :src="mapUrl" />
                </figure>
                 </router-link>
                <b-button type="is-info" tag="router-link" size="is-large" expanded :to="getCampaignDetailLink(selected.map_name)">View</b-button>
            </div>
        </div>
      </div>
    </div>
</div>
</template>

<script>
import NoMapImage from '@/assets/no_map_image.png'
import { getMapName, getMapImage} from '../js/map'
export default {
    data() {
        return {
            maps: [],
            details: null,
            selected: null,
            loading: true
        }
    },
    methods: {
        fetchMaps() {
            this.loading = true;
            this.$http.get(`/api/maps`, { cache: true })
            .then(res => {
                this.maps = res.data.maps;
                if(this.$route.params.map) {
                    const map = this.maps.find(v => v.map_name.toLowerCase() == this.$route.params.map.toLowerCase())
                    if(map) {
                        this.selected = map;
                    }
                }
            })
            .catch(err => {
                console.error('Fetch error', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Error ocurred while fetching maps',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchMaps()
                })
            }).finally(() => this.loading = false)
        },
        onDetailsOpen(obj) {
            this.details = obj;
        },
        onMapSelect() {
            //this.$router.replace(`/maps/${sel.map_name}`)
        },
        getCampaignDetailLink(mapName) {
            const id = getMapName(mapName).toLowerCase().replace(/\s/, '-');
            return `/maps/${id}/details`
        }
    },
    watch: {
        '$route.params.map': function (oldv) {
            if(!oldv) {
                this.selected = null;
            }
        }
    },
    computed: {
        mapUrl() {
            if(this.selected) {
                const imageUrl = getMapImage(this.selected.map_name);
                return imageUrl ? `/img/${imageUrl}` : NoMapImage;
            }
            return NoMapImage
        }
    },
    mounted() {
        this.fetchMaps();
    },
    filters: {
        formatMap(str) {
            return getMapName(str)
        },
    }
}
</script>