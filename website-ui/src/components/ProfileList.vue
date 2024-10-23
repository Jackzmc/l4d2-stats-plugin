<template>
    <b-table
        v-bind="$attrs"
        ref="profileList"
        class="has-text-left"

        @page-change="page => $emit('page-change', page)"
    >
          <b-table-column field="last_alias" label="Player Name" v-slot="props" >
              <b-tooltip label="Click to view their profile" position="is-right">
                  <router-link :to="getUserLink(props.row)" class="vcell">
                      <p><strong>{{ props.row.last_alias }}</strong></p>
                  </router-link>
              </b-tooltip>
          </b-table-column>
          <b-table-column field="points" label="Points" v-slot="props">
              <span style="color: blue">{{ Math.round(props.row.points) | formatNumber }}</span>
              <!-- <em> {{Math.round(props.row.points / (props.row.minutes_played / 60)) | formatNumber}} p/h</em> -->
          </b-table-column>
          <b-table-column label="Last Played" v-slot="props">
              {{ formatDateAndRel(props.row.last_join_date * 1000) }}
          </b-table-column>
          <b-table-column field="minutes_played" label="Total Playtime" v-slot="props">
              {{ humanReadable(props.row.minutes_played) }}
          </b-table-column>
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
import { formatDuration, formatDistanceToNow } from 'date-fns'
export default {
  methods: {
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
    },
    getUserLink({steamid}) {
        return `/user/${steamid}`
    },
    formatDateAndRel(inp) {
        if(inp <= 0 || isNaN(inp)) return ""
        try {
            const rel = formatDistanceToNow(new Date(inp))
            return `${rel} ago`
        }catch(err) {
            return ""
        }
    },
  }
}
</script>


<style scoped>
.valign {
  vertical-align: middle;
}
</style>
