<template>
    <b-table 
        v-bind="$attrs" 
        ref="profileList" 
        :default-sort="[points, minutes_played]"

        @page-change="page => $emit('page-change', page)" 
    >
        <template slot-scope="props">
            <b-table-column width="20">
                <b-tooltip label="Click to access their profile">
                    <router-link :to="'/user/' + props.row.steamid" icon-right="angle-right">
                        <b-icon icon="angle-right" />
                    </router-link>
                </b-tooltip>
            </b-table-column>
            <b-table-column field="last_alias" label="Player" >
                <b-tooltip label="Click to access their profile">
                    <router-link :to="'/user/' + props.row.steamid">
                        <strong>{{ props.row.last_alias }}</strong>
                    </router-link>
                </b-tooltip>
            </b-table-column>
            <b-table-column field="points" label="Points" >
                <span style="color: blue">{{ props.row.points | formatNumber }}</span>
            </b-table-column>
            <b-table-column field="top_gamemode" label="Top Gamemode" >
                {{ props.row.top_gamemode }}
            </b-table-column>
            <b-table-column field="minutes_played" label="Total Playtime" >
                <span style="color: blue">{{ props.row.minutes_played | humanReadable }}</span>
            </b-table-column>
        </template>
        <template slot="empty">
            <section class="section">
                <div class="content has-text-grey has-text-centered" v-if="$attrs.search !== undefined">
                    <p>Could not find any recorded users matching your query.</p>
                    <br>
                    <b-button type="is-info" tag="router-link" to="/">Return Home</b-button>
                </div>
                <div class="content has-text-grey has-text-centered" v-else>
                    <p>Could not find any users.</p>
                </div>
            </section>
        </template>
    </b-table>
</template>


<script>
import {formatDuration} from 'date-fns'

export default {
    filters: {
        humanReadable(minutes) {
            let hours = Math.floor(minutes / 60);  
            const days = Math.floor(hours / 24);
            minutes = minutes % 60;
            const day_text = days == 1 ? 'day' : 'days'
            const min_text = minutes == 1 ? 'minute' : 'minutes'
            const hour_text = hours == 1 ? 'hour' : 'hours'
            if(days >= 1) {
                hours = hours % 24; 
                return `${days} ${day_text}, ${hours} ${hour_text}`
            }else if(hours >= 1) {
                return `${hours} ${hour_text}, ${minutes} ${min_text}` 
            }else{
                return `${minutes} ${min_text}`
            }
        },
        formatMinutes(min) {
            return formatDuration({minutes: parseInt(min)})
        }
    },
}
</script>