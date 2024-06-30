import Vue from 'vue'
import App from './App.vue'
import router from './router'

import Buefy from 'buefy'
import 'buefy/dist/buefy.css'

import Axios from 'axios'
import vueDebounce from 'vue-debounce'
import Meta from 'vue-meta'

import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { faCog, faSearch, faShare, faSyncAlt, faAngleLeft, faAngleRight, faCaretDown, faCaretUp, faTimesCircle, faLink, faChevronCircleLeft, faChevronCircleRight, faCheck, faArrowUp, faStar as fasStar } from '@fortawesome/free-solid-svg-icons'
import { faStar as farStar } from '@fortawesome/free-regular-svg-icons'

library.add(faCog, faSearch, faShare, faSyncAlt, faAngleLeft, faAngleRight, faCaretDown, faCaretUp, faTimesCircle, faLink, faChevronCircleLeft, faChevronCircleRight, faCheck, faArrowUp, fasStar, farStar);

Vue.component('font-awesome-icon', FontAwesomeIcon)
Vue.use(vueDebounce)
Vue.use(Buefy, { defaultIconPack: 'fas', defaultIconComponent: 'font-awesome-icon' })
Vue.use(Meta)
Vue.prototype.$http = Axios.create({
	baseURL: '/',
	headers: { 'Cache-Control': 'no-cache' },
});
Vue.prototype.$SHARE_URL = process.env.VUE_APP_SHARE_URL;

Vue.config.productionTip = false
Vue.filter('formatNumber', (num) => {
  if(!num) return 0;
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
})

new Vue({
  router,
  render: h => h(App)
}).$mount('#app')
