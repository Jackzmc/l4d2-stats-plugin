<template>
<div>
    <h2 class='title is-2'>Campaign Statistics</h2>
    <b-table :data="maps" detailed>
        <template slot-scope="props">
            <b-table-column field="map_name" label="Map" >
                <router-link :to="'/maps/' + props.row.map_name">{{ props.row.map_name | formatMap }}</router-link>
            </b-table-column>
            <b-table-column field="wins" label="Wins" centered>
                {{ props.row.wins | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Realism" centered>
                {{ props.row.realism | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Easy" centered>
                {{ props.row.difficulty_easy | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Normal" centered>
                {{ props.row.difficulty_normal | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Advanced" centered>
                {{ props.row.difficulty_advanced | formatNumber }}
            </b-table-column>
            <b-table-column field="realism" label="Times on Expert" centered>
                {{ props.row.difficulty_expert | formatNumber }}
            </b-table-column>
        </template>
        <template slot="detail" slot-scope="props">
            <p><strong>Map: </strong>{{props.row.map_name}}</p>
            <hr>
            <h5 class="title is-5">Best Time</h5>
            <p class="subtitle is-6">5 hours, 2 minutes</p>
        </template>
    </b-table>
</div>
</template>

<script>
export default {
    props: ['user', 'maps'],
    filters: {
        formatMap(str) {
            console.log(str.substring(0,1))
            switch(str.substring(0,3)) {
                case "c1m": return "Dead Center"
                case "c2m": return "Dark Carnival"
                case "c3m": return "Swamp Fever"
                case "c4m": return "Hard Rain"
                case "c5m": return "The Parish"
                case "c6m": return "The Passing"
                case "c7m": return "The Sacrifice"
                case "c8m": return "No Mercy"
                case "c9m": return "Death Toll"
                case "c10": return "Crash Course"
                case "c11": return "Dead Air"
                case "c12": return "Blood Harvest"
                case "c13": return "Cold Stream"
                default: return str;
            }
        }
    }
}
</script>