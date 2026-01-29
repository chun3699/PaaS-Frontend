<script setup lang="ts">
const config = useRuntimeConfig()
const { login } = useAuth()

const form = reactive({ username: '', password: '' })
const errorMsg = ref('')
const isLoading = ref(false)

const handleLogin = async () => {
  isLoading.value = true
  errorMsg.value = ''

  try {
    // credentials: 'include' สำคัญมาก เพื่อให้ Browser รับ Cookie
    await $fetch(`${config.public.apiBase}/login`, {
      method: 'POST',
      body: form,
      credentials: 'include'
    })
    
    login() // เปลี่ยนหน้า
  } catch (e: any) {
    errorMsg.value = e.data?.error || 'เข้าสู่ระบบไม่สำเร็จ'
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 to-slate-800">
    <div class="bg-white p-8 rounded-xl shadow-2xl w-96 transform transition-all">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-slate-800">Admin Login</h1>
        <p class="text-gray-500 text-sm mt-2">ระบบจัดการ Portainer PaaS</p>
      </div>

      <form @submit.prevent="handleLogin" class="space-y-5">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Username</label>
          <input v-model="form.username" type="text" class="w-full border-gray-300 border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" required />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
          <input v-model="form.password" type="password" class="w-full border-gray-300 border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" required />
        </div>

        <div v-if="errorMsg" class="p-3 bg-red-50 text-red-600 text-sm rounded-lg border border-red-200 text-center">
          {{ errorMsg }}
        </div>

        <button type="submit" :disabled="isLoading" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-bold transition-colors disabled:bg-gray-400">
          {{ isLoading ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ' }}
        </button>
      </form>
    </div>
  </div>
</template>