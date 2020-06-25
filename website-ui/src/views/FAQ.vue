<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
            <h1 class="title">
                Frequently Asked Questions
            </h1>
            </div>
        </div>
    </section>
    <br>
    <div class="container has-text-left">
        <div class="column">
            <h5 class="title is-5">What is this?</h5>
            <p>This is a plugin you can install on any sourcemod l4d2 server, and it will record all the statistics you see on a user's page. This includes kills, deaths, damage and more. This plugin sends the database to a MySQL database which then you can view on this webpage. </p>
            <hr>
            <h5 class="title is-5">How are points calculated?</h5>
            <b-collapse :open="false" class="card" animation="slide">
                <div
                    slot="trigger"
                    slot-scope="props"
                    class="card-header"
                    role="button">
                    <p class="card-header-title">
                        View Amounts
                    </p>
                    <a class="card-header-icon">
                        <b-icon
                            :icon="props.open ? 'caret-up' :  'caret-down'">
                        </b-icon>
                    </a>
                </div>
                <div class="card-content">
                    <div class="content">
                        <ul>
                            <li><span class="has-text-success">+1</span> per common killed (any damage type)</li>
                            <li><span class="has-text-success">+2</span> per common headshot</li>
                            <li><span class="has-text-success">+50</span> per infected kill</li>
                            <li><span class="has-text-success">+200</span> per tank kill</li>
                            <li><span class="has-text-success">+50</span> per tank kill solo (in addition to tank kill)</li>
                            <li><span class="has-text-success">+50</span> per tank kill melee (in addition to tank kill))</li>
                            <li><span class="has-text-success">+100</span> per witch kill</li>
                            <li><span class="has-text-success">+10</span> per heal teammate</li>
                            <li><span class="has-text-success">+3</span> per revive teammate</li>
                            <li><span class="has-text-success">+9</span> per teammate defibbed</li>
                            <li><span class="has-text-success">+3</span> per ammo pack deploy</li>
                            <li><span class="has-text-success">+300</span> per finale win</li>
                            <br>
                            <li><span class="has-text-danger">-20</span> for teammate kill</li>
                            <li><span class="has-text-danger">-1</span> per teammate dmg</li>
                        </ul>
                    </div>
                </div>
            </b-collapse>
        </div>
    </div>
    <br>
</div>
</template>
