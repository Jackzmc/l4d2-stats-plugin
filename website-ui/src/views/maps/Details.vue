<template>
<div>
  <section class="hero is-dark">
    <div class="hero-body">
      <div class="container has-text-centered">
        <h1 class="title">
          {{ mapInfo.name }}
        </h1>
        <p class="subtitle">
          {{ this.$route.params.id }}
        </p>
        <p class="subtitle" v-if="avgRating">
          <b-icon size="is-small" pack="fas" icon="star" v-for=" i in Math.round( avgRating ) " :key="i" />
          <b-icon size="is-small" pack="far" icon="star" v-for=" i in 5 - Math.round( avgRating )  " :key="i + 10" />
          {{ Number( avgRating ).toFixed( 1 ) }}
        </p>
      </div>
    </div>
  </section>
  <br>
  <div class="container is-fluid">
    <div class="columns">
      <div class="column">
        <h4 class="title is-4">Ratings ({{ ratings.length }})</h4>
        <div class="columns" v-if="ratings">
          <div class="column is-3" v-for="rating, i in ratings" :key="i">
            <div class="card">
              <div class="card-content">
                <div class="media">
                  <div class="media-content">
                    <p class="title is-4">{{ rating.user.name }}</p>
                    <p class="subtitle is-6">{{ rating.user.id }}</p>
                  </div>
                </div>
                <b-icon size="is-small" pack="fas" icon="star" v-for=" i in rating.value " :key="i" />
                <b-icon size="is-small" pack="far" icon="star" v-for="  i in 5 - rating.value  " :key="i + 10" />
                {{ rating.value }}
                <article class="message" v-if="rating.comment">
                  <div class="message-body">
                    {{ rating.comment }}
                  </div>
                </article>
              </div>
            </div>
          </div>
        </div>
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
            mapInfo: { name: "Unknown" },
            ratings: [],
            avgRating: null,
            loading: true
        }
    },
    methods: {
        async fetchDetails() {
            this.loading = true;
            this.$http.get(`/api/maps/${this.$route.params.id}`, { cache: true })
            .then(res => {
              this.mapInfo = res.data.map
              this.ratings = res.data.ratings
              this.avgRating = res.data.avgRating
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
        this.fetchDetails();
    },
}
</script>
