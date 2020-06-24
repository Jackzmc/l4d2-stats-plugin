<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
            <h1 class="title">
                Search results for '{{this.query}}'
            </h1>
            <p class="subtitle is-4">{{size}} result{{size | pluralMode}}</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container">
        <ProfileList :data="results" search />
    </div>
</div>
</template>

<script>
import Axios from 'axios'
import {formatDuration} from 'date-fns'
import ProfileList from '@/components/ProfileList'
export default {
    mounted() {
        this.search();
    },
    data() {
        return {
            results:[],
            size: 0
        }
    },
    components: {
        ProfileList
    },
    computed: {
        query() {
            return this.$route.params.query.trim()
        }
    },
    methods:{
        search() {
            if(this.query.length == 0) return;
            Axios.get(`/api/search/${this.query}`)
            .then(res => {
                this.results = res.data;
                this.size = res.data.length;
            }) 
            .catch(err => {
                console.error('Fetch error', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Error ocurred while searching.',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.search()
                })
            })
        }
    },
    watch: {
        '$route.params.query': function () {
            this.search()
        }
    },
    filters: {
        humanReadable(minutes) {
            let hours = Math.floor(minutes / 60);  
            const days = Math.floor(hours / 24);
            minutes = minutes % 60;
            const min_text = minutes == 1 ? 'minute' : 'minutes'
            const hour_text = hours == 1 ? 'hour' : 'hours'
            if(days >= 1) {
                hours = hours % 24; 
                return `${days} days, ${hours} ${hour_text}`
            }else if(hours >= 1) {
                return `${hours} ${hour_text}, ${minutes} ${min_text}` 
            }else{
                return `${minutes} ${min_text}`
            }
        },
        formatMinutes(min) {
            return formatDuration({minutes: min})
        },
        pluralMode(inp) {
            const number = parseInt(inp);
            return (number == 1) ? "" : "s" 
        }
    },
}
</script>