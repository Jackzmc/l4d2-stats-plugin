<template>
     <h5 :id="id" class="title is-5">
        <div class="level">
            <div class="level-left">
                <div class="level-item has-text-centered">
                    <a :href="'#'+id" class="icon">
                        <b-icon size="is-small" icon="link" />
                    </a>
                    <p>{{text}}</p>
                </div>
            </div>
        </div>
    </h5>
</template>

<script>
export default {
    props:['id','text']
}
</script>