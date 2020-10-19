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
                        <a href="#"><b-icon icon="angle-right" /></a>
                    </b-table-column>
                    <b-table-column field="map_name" label="Map" >
                        <router-link :to="'/maps/' + props.row.map_name">
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
                <h5 class="title is-5">Map Information</h5>
                <figure class="image is-2by1">
                    <img :src="mapUrl" />
                </figure>
                <br>
                <h6 class="title is-6">{{ selected.map_name | formatMap }}</h6>
                <p class="subtitle is-6">{{ selected.map_name}}</p>
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
            maps:[],
            details: null,
            selected: null,
            loading: true
        }
    },
    methods: {
        fetchMaps() {
            this.loading = true;
            this.$http.get(`/api/maps`,{cache:true})
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
        onMapSelect(sel) {
            this.$router.replace(`/maps/${sel.map_name}`)
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
                console.log(this.selected.map_name, imageUrl)
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