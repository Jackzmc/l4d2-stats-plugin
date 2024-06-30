<template>
<div>
  <section class="hero is-dark">
    <div class="hero-body">
      <div class="container has-text-centered">
        <h1 class="title">

        </h1>
        <p class="subtitle">

        </p>
      </div>
    </div>
  </section>
  <br>
  <div class="container is-fluid">
    <div class="columns">
      <div class="column">
        <h4 class="title is-4">Ratings</h4>
        <!-- {{ ratings }} -->
        coming soon.
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
        async fetchDetails() {
            this.loading = true;
            this.$http.get(`/api/ratings/${this.$route.params.map}`, { cache: true })
            .then(res => {
                this.ratings = res.data.ratings
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
