import { createI18n } from 'vue-i18n'
import vi from './vi'
import en from './en'

// Read the saved language from localStorage, or default to 'vi'
const savedLocale = localStorage.getItem('app-lang') || 'vi'

const i18n = createI18n({
    legacy: false, // Set to false to use Composition API features
    locale: savedLocale,
    fallbackLocale: 'vi',
    messages: {
        vi,
        en
    }
})

export default i18n
