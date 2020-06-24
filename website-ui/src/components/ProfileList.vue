<template>
    <b-table v-bind="$attrs">
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
                <span style="color: blue">{{ props.row.minutes_played | formatMinutes }}</span>
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
