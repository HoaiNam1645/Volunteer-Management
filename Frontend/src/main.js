import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import BoCucChinh from './layout/wrapper/Bo_Cuc_Chinh.vue'
import BoCucXacThuc from './layout/wrapper/Bo_Cuc_Xac_Thuc.vue'
import BoCucAdmin from './layout/wrapper/Bo_Cuc_Admin.vue'
import i18n from './i18n'

const app = createApp(App)

app.use(router)
app.use(i18n)
app.component("default-layout", BoCucChinh);
app.component("auth-layout", BoCucXacThuc);
app.component("admin-layout", BoCucAdmin);

app.mount("#app")