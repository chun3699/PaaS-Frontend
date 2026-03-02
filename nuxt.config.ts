// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  // ✅ 1. เพิ่ม Tailwind เข้าไป
  modules: ['@nuxtjs/tailwindcss'],

  // ✅ 2. ตั้งค่าตัวแปรระบบ (เอาไว้เรียก URL Backend)
  runtimeConfig: {
    public: {
      // apiBase: 'http://10.33.4.47:3000/api' 
      apiBase: 'http://localhost:3030/api' // ชี้ไปที่ Backend ของเรา
    }
  }

})
