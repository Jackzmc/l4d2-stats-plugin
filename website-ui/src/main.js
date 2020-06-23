import Vue from 'vue'
import App from './App.vue'
import router from './router'

import Buefy from 'buefy'
import 'buefy/dist/buefy.css'

import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { library } from '@fortawesome/fontawesome-svg-core'
import { faCog, faSearch, faSyncAlt, faAngleLeft, faAngleRight, faCaretDown, faCaretUp } from '@fortawesome/free-solid-svg-icons'
library.add(faCog, faSearch, faSyncAlt, faAngleLeft, faAngleRight, faCaretDown, faCaretUp);

Vue.component('font-awesome-icon', FontAwesomeIcon)
Vue.use(Buefy, { defaultIconPack: 'fas', defaultIconComponent: 'font-awesome-icon' })

Vue.config.productionTip = false
Vue.filter('formatNumber', (num) => {
  if(!num) return 0;
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
})

new Vue({
  router,
  render: h => h(App)
}).$mount('#app')
