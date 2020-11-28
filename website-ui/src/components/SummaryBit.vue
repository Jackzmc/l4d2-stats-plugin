<template>
<div>
    <nav class="level">
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Boomers Killed</p>
            <p class="title"><ICountUp :endVal="values.boomer_kills" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Jockeys Killed</p>
            <p class="title"><ICountUp :endVal="values.jockey_kills" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Smokers Killed</p>
            <p class="title"><ICountUp :endVal="values.smoker_kills" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Spitters Killed</p>
            <p class="title"><ICountUp :endVal="values.spitter_kills" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Hunters Killed</p>
            <p class="title"><ICountUp :endVal="values.hunter_kills" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Chargers Killed</p>
            <p class="title"><ICountUp :endVal="values.charger_kills" /></p>
            </div>
        </div>
    </nav>
    <nav class="level">
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Pills Used</p>
            <p class="title"><ICountUp :endVal="values.PillsUsed" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Adrenalines Used</p>
            <p class="title"><ICountUp :endVal="values.AdrenalinesUsed" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Kits Used (Self)</p>
            <p class="title"><ICountUp :endVal="values.MedkitsUsed - values.FirstAidShared" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Kits Used (Shared)</p>
            <p class="title"><ICountUp :endVal="values.FirstAidShared" /></p>
            </div>
        </div>
    </nav>
    <nav class="level">
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Incaps</p>
            <p class="title"><ICountUp :endVal="values.Incaps" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Deaths</p>
            <p class="title"><ICountUp :endVal="values.Deaths" /></p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Revives (Others)</p>
            <p class="title"><ICountUp :endVal="values.ReviveOtherCount" /></p>
            </div>
        </div>
    </nav>
</div>
</template>

<script>
import ICountUp from 'vue-countup-v2';
export default {
    props: ['values', 'type'],
    components: {
        ICountUp
    },
    methods: {
        formatNumber(number) {
            if(!number) return 0;
            return Math.round(number).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        },
    }
}
</script>