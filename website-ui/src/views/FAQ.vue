<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
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
            <p>This is a page for my <a href="https://github.com/Jackzmc/l4d2-stats-plugin">l4d2 stats plugin</a>. View information on how to set it up on the github linked. The plugin records kills, deaths, damage, skills and more from various left 4 dead game sessions and are displayed neatly on this website. This website is home to my personal servers I host, some for friends and some are public (see 'public' tags). </p>
            <hr>
            <b-collapse :open="false" class="card" animation="slide">
                <div
                    slot="trigger"
                    slot-scope="props"
                    class="card-header"
                    role="button">
                    <p class="card-header-title">
                        How are points calculated?
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
                            <li><span class="has-text-success">+6</span> per special kill</li>
                            <li><span class="has-text-success">+100</span> per tank kill</li>
                            <li><span class="has-text-success">+20</span> per tank kill solo (in addition to tank kill)</li>
                            <li><span class="has-text-success">+50</span> per tank kill melee (in addition to tank kill))</li>
                            <li><span class="has-text-success">+50</span> per witch kill</li>
                            <li><span class="has-text-success">+10</span> per heal teammate</li>
                            <li><span class="has-text-success">+5</span> per revive teammate</li>
                            <li><span class="has-text-success">+7</span> per teammate defibbed</li>
                            <li><span class="has-text-success">+2</span> per ammo pack deploy</li>
                            <li><span class="has-text-success">+200</span> per finale win</li>
                            <br>
                            <li><span class="has-text-danger">-100</span> for teammate kill</li>
                            <li><span class="has-text-danger">-10</span> per teammate dmg</li>
                        </ul>
                    </div>
                </div>
            </b-collapse>
            <b-collapse :open="false" class="card" animation="slide">
                            <div
                    slot="trigger"
                    slot-scope="props"
                    class="card-header"
                    role="button">
                    <p class="card-header-title">
                        How is campaign MVP calculated?
                    </p>
                    <a class="card-header-icon">
                        <b-icon
                            :icon="props.open ? 'caret-up' :  'caret-down'">
                        </b-icon>
                    </a>
                </div>
                <div class="card-content">
                    <div class="content">
                        <p>Campaign MVP is determined by the following fields:</p>
                        <ol>
                            <li>Special Infected Killed <em>(highest number)</em></li>
                            <li>Survivor FF Count <em>(lowest number)</em></li>
                            <li>Zombie Kills <em>(highest number)</em></li>
                            <li>Damage Taken <em>(lowest number)</em></li>
                        </ol>
                        <p>When a campaign is fetched, the list of sessions for that campaign are sorted in the order listed above. The first player in the list will be assigned the MVP.</p>
                    </div>
                </div>
            </b-collapse>
        </div>
    </div>
    <br>
</div>
</template>
