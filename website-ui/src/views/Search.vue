<template>
    <div class="container">
        <h4 class="title is-4">Search results for '{{$route.params.query}}'</h4>
        <p class="subtitle is-5">Found {{size}} results</p>
        <br>
        <b-table :data="results">
            <template slot-scope="props">
                <b-table-column width="20">
                    <b-tooltip label="Click to access their profile">
                        <router-link :to="'/user/' + props.row.steamid" icon-right="angle-right"><b-icon icon="angle-right" /></router-link>
                    </b-tooltip>
                </b-table-column>
                <b-table-column field="last_alias" label="Player" >
                    <b-tooltip label="Click to access their profile">
                        <router-link :to="'/user/' + props.row.steamid">{{ props.row.last_alias }}</router-link>
                    </b-tooltip>
                </b-table-column>
                <b-table-column field="points" label="Points" >
                    {{ props.row.points | formatNumber }}
                </b-table-column>
                <b-table-column field="top_gamemode" label="Top Gamemode" >
                    {{ props.row.top_gamemode }}
                </b-table-column>
                <b-table-column field="minutes_played" label="Total Playtime" >
                    {{ props.row.minutes_played | formatMinutes }}
                </b-table-column>
            </template>
            <template slot="empty">
                <section class="section">
                    <div class="content has-text-grey has-text-centered">
                        <p>Could not find any recorded users matching your query.</p>
                        <br>
                        <b-button type="is-info" tag="router-link" to="/">Return Home</b-button>
                    </div>
                </section>
            </template>
        </b-table>
    </div>
</template>

<script>
import Axios from 'axios'
import {formatDuration} from 'date-fns'
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
    methods:{
        search() {
            Axios.get(`/api/search/${this.$route.params.query}`)
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
        }
    }
}
</script>