<template>
<div v-if="!loading">
  <h2 class='title is-2'>Weapon Statistics</h2>
  <h4 class="title is-4">Primary Weapons</h4>
  <table class="table is-fullwidth has-background-dark has-text-white">
    <thead>
      <tr>
        <th style="width:40%" class="has-text-white">Weapon</th>
        <th class="has-text-white">Time Used</th>
        <th class="has-text-white">Usage</th>
        <!-- <th class="has-text-white">Total Damage</th> -->
        <th class="has-text-white">Kills</th>
        <th class="has-text-white">Headshots</th>
      </tr>
    </thead>
    <tbody>
        <tr v-for="weapon in weapons" :key="weapon.weapon">
          <td>
            <img :src="getImageUrl(weapon.weapon)" class="pr-4 vcenter"/>
            <b style="vertical-algin:top">{{ formatWeapon(weapon.weapon) }}</b><br>
            <em style="vertical-algin:middle" class="is-size-7 is-inline pt-2">{{weapon.weapon}}</em>
          </td>
          <td>
            {{formatMinutes(weapon.minutesUsed)}}
          </td>
          <td>
            {{calculatePercent(weapon.minutesUsed)}}
          </td>
          <!-- <td>{{weapon.totalDamage}} HP</td> -->
          <td>{{formatNumber(weapon.kills)}}</td>
          <td>{{formatNumber(weapon.headshots)}}</td>
        </tr>
    </tbody>
  </table>
  <h4 class="title is-4">Melee Weapons</h4>
  <table class="table is-fullwidth has-background-dark has-text-white">
    <thead>
      <tr>
        <th style="width:40%" class="has-text-white">Weapon</th>
        <th class="has-text-white">Time Used</th>
        <th class="has-text-white">Usage</th>
        <!-- <th class="has-text-white">Total Damage</th> -->
        <th class="has-text-white">Kills</th>
        <th class="has-text-white">Headshots</th>
      </tr>
    </thead>
    <tbody>
        <tr v-for="weapon in melees" :key="weapon.weapon">
          <td>
            <img :src="getImageUrl(weapon.weapon)" class="pr-4 vcenter"/>
            <b style="vertical-algin:top">{{ formatWeapon(weapon.weapon) }}</b><br>
            <em style="vertical-algin:middle" class="is-size-7 is-inline pt-2">{{weapon.weapon}}</em>
          </td>
          <td>
            {{formatMinutes(weapon.minutesUsed)}}
          </td>
          <td>
            {{calculatePercent(weapon.minutesUsed)}}
          </td>
          <!-- <td>{{weapon.totalDamage}} HP</td> -->
          <td>{{formatNumber(weapon.kills)}}</td>
          <td>{{formatNumber(weapon.headshots)}}</td>
        </tr>
    </tbody>
  </table>
</div>
</template>

<script>


import { formatDistance } from 'date-fns'
import GameInfo from '@/assets/gameinfo.json'
export default {
  metaInfo() {
      return {
        title: "Weapon Statistics"
      }
    },
    props: ['user'],
    data() {
        return {
          weapons: [],
          melees: [],
          loading: false,
          totalMinutes: 0
        }
    },
    mounted() {
        this.fetchStats()
    },
    methods: {
        calculatePercent(minutesUsed) {
          return (minutesUsed / this.totalMinutes * 100).toFixed(1) + "%"
        },
        getImageUrl(weapon) {
          return `/img/weapons/${weapon}.jpg`
        },
        formatWeapon(weapon) {
          let name = GameInfo.weapons[weapon.slice(7)] ?? GameInfo.weapons[weapon]
          return name ?? weapon
        },
        formatMinutes(minutes) {
          return formatDistance(0, new Date(minutes * 60000))
        },
        formatNumber(num) {
          return Number(num).toLocaleString()
        },
        fetchStats() {
            this.loading = true;
            this.weapons = []
            this.melees = []
            this.$http.get(`/api/user/${this.user.steamid}/weapons`,{cache:true})
            .then(r => {
                const weapons = r.data.weapons
                .sort((a,b) => b.minutesUsed - a.minutesUsed)

                for(const weapon of weapons) {
                  this.totalMinutes += weapon.minutesUsed
                  if(weapon.weapon.startsWith("weapon")) {
                    this.weapons.push(weapon)
                  } else {
                    this.melees.push(weapon)
                  }
                }
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch weapon statistics',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchStats()
                })
            })
            .finally(() => this.loading = false)
        }
    }
}
</script>

<style scoped>
.number-cell {
    color: blue;
}
.table >>> td, .table >>> th {
  padding: 1em 1em !important;
  background-color: rgb(32, 32, 32);
}
.vcenter {
  vertical-align: middle;
}
</style>
