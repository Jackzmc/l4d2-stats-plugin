import Vue from 'vue'
import App from './App.vue'
import router from './router'

import Buefy from 'buefy'
import 'buefy/dist/buefy.css'

import Axios from 'axios'
import { cacheAdapterEnhancer} from 'axios-extensions';
import vueDebounce from 'vue-debounce'


import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { library } from '@fortawesome/fontawesome-svg-core'
import { faCog, faSearch, faShare, faSyncAlt, faAngleLeft, faAngleRight, faCaretDown, faCaretUp, faTimesCircle, faLink, faChevronCircleLeft, faChevronCircleRight, faCheck, faArrowUp } from '@fortawesome/free-solid-svg-icons'

library.add(faCog, faSearch, faShare, faSyncAlt, faAngleLeft, faAngleRight, faCaretDown, faCaretUp, faTimesCircle, faLink, faChevronCircleLeft, faChevronCircleRight, faCheck, faArrowUp);

Vue.component('font-awesome-icon', FontAwesomeIcon)
Vue.use(vueDebounce)
Vue.use(Buefy, { defaultIconPack: 'fas', defaultIconComponent: 'font-awesome-icon' })
Vue.prototype.$http = Axios.create({
	baseURL: '/',
	headers: { 'Cache-Control': 'no-cache' },
	// disable the default cache
	adapter: cacheAdapterEnhancer(Axios.defaults.adapter, { enabledByDefault: false })
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
