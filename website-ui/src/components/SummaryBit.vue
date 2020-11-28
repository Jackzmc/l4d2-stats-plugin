<template>
<div>
    <nav class="level">
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Boomers Killed</p>
            <p class="title">{{formatNumber(values.boomer_kills)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Jockeys Killed</p>
            <p class="title">{{formatNumber(values.jockey_kills)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Smokers Killed</p>
            <p class="title">{{formatNumber(values.smoker_kills)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Spitters Killed</p>
            <p class="title">{{formatNumber(values.spitter_kills)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Hunters Killed</p>
            <p class="title">{{formatNumber(values.hunter_kills)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Chargers Killed</p>
            <p class="title">{{formatNumber(values.charger_kills)}}</p>
            </div>
        </div>
    </nav>
    <nav class="level">
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Pills Used</p>
            <p class="title">{{formatNumber(values.PillsUsed)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Adrenalines Used</p>
            <p class="title">{{formatNumber(values.AdrenalinesUsed)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Kits Used (Self)</p>
            <p class="title">{{formatNumber(values.MedkitsUsed - values.FirstAidShared)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Kits Used (Shared)</p>
            <p class="title">{{formatNumber(values.FirstAidShared)}}</p>
            </div>
        </div>
    </nav>
    <nav class="level">
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Incaps</p>
            <p class="title">{{formatNumber(values.Incaps)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Deaths</p>
            <p class="title">{{formatNumber(values.Deaths)}}</p>
            </div>
        </div>
        <div class="level-item has-text-centered">
            <div>
            <p class="heading">Revives (Others)</p>
            <p class="title">{{formatNumber(values.ReviveOtherCount)}}</p>
            </div>
        </div>
    </nav>
</div>
</template>

<script>
export default {
    props: ['values', 'type'],
    methods: {
        formatNumber(number) {
            if(!number) return 0;
            return Math.round(number).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        },
    }
}
</script>