<template>
<div>
  <section class="hero is-dark">
    <div class="hero-body">
      <div class="container has-text-centered">
        <h1 class="title">
            Campaigns
        </h1>
        <p class="subtitle">Sorted by most rated</p>
      </div>
    </div>
  </section>
  <br>
  <div class="container is-fluid">
    <div class="columns">
      <div class="column">
        <b-table :loading="loading"  :data="ratings">
            <b-table-column v-slot="props" field="map_name" label="Map">
              <router-link :to="getCampaignDetailLink( props.row.map_id )">
                <strong>{{ props.row.map_name || props.row.map_id }}</strong>
              </router-link>
            </b-table-column>
            <b-table-column v-slot="props" field="games_played" label="Games Played">
                {{ props.row.games_played | formatNumber }}
            </b-table-column>
            <b-table-column v-slot="props" field="avg_rating" label="Rating">
            <b-icon size="is-small" pack="fas" icon="star" v-for="i in Math.round(props.row.avg_rating)" :key="i" />
            <b-icon size="is-small" pack="far" icon="star" v-for="i in 5-Math.round( props.row.avg_rating ) " :key="i+10" />
             {{ Number(props.row.avg_rating).toFixed(1) }}
            </b-table-column>
        </b-table>
      </div>
    </div>
  </div>
</div>
</template>

<script>
import NoMapImage from '@/assets/no_map_image.png'
import { getMapName, getMapImage} from '@/js/map'
export default {
    data() {
        return {
            ratings: [],
            loading: true
        }
    },
    methods: {
        async fetchMaps() {
            this.loading = true;
            this.$http.get(`/api/ratings`, { cache: true })
            .then(res => {
                this.ratings = res.data
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
        getCampaignDetailLink(mapId) {
            return `/maps/${mapId}`
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
                return imageUrl ? `/img/posters/${imageUrl}` : NoMapImage;
            }
            return NoMapImage
        }
    },
    mounted() {
        this.fetchMaps();
    },
}
</script>
