<script setup lang="ts">
definePageMeta({ layout: 'dashboard' })
const config = useRuntimeConfig()

// Data
const envs = ref<any[]>([])
const users = ref<any[]>([])

// Form
const form = reactive({ environmentId: '', userId: '', amount: 1 })
const result = ref<any>(null)
const isLoading = ref(false)

// --- 🔍 Logic: Searchable Environment ---
const searchEnvQuery = ref('')
const isEnvDropdownOpen = ref(false)
const selectedEnvName = ref('')

const filteredEnvs = computed(() => {
  const query = searchEnvQuery.value.toLowerCase()
  if (!query) return envs.value
  return envs.value.filter((e: any) => e.name.toLowerCase().includes(query))
})

const selectEnv = (env: any) => {
  form.environmentId = env.id
  selectedEnvName.value = env.name
  isEnvDropdownOpen.value = false
  searchEnvQuery.value = ''
}

const onSearchEnvType = () => {
  if (!isEnvDropdownOpen.value) isEnvDropdownOpen.value = true
  if (form.environmentId) { 
    form.environmentId = ''
    selectedEnvName.value = '' // ✅ แก้: เติม .value
  }
}

const closeEnvDropdown = () => { setTimeout(() => { isEnvDropdownOpen.value = false }, 200) }
// ----------------------------------------

// --- 🔍 Logic: Searchable User ---
const searchUserQuery = ref('')
const isUserDropdownOpen = ref(false)
const selectedUserName = ref('')

const filteredUsers = computed(() => {
  const query = searchUserQuery.value.toLowerCase()
  if (!query) return users.value
  return users.value.filter((u: any) => u.username.toLowerCase().includes(query) || u.id_users.toString().includes(query))
})

const selectUser = (user: any) => {
  form.userId = user.id_users
  selectedUserName.value = user.username
  isUserDropdownOpen.value = false
  searchUserQuery.value = ''
}

const onSearchUserType = () => {
  if (!isUserDropdownOpen.value) isUserDropdownOpen.value = true
  if (form.userId) { 
    form.userId = ''
    selectedUserName.value = '' // ✅ แก้: เติม .value
  }
}

const closeUserDropdown = () => { setTimeout(() => { isUserDropdownOpen.value = false }, 200) }
// ----------------------------------------

// Load Data
const loadData = async () => {
  try {
    const [resEnv, resUser] = await Promise.all([
      $fetch(`${config.public.apiBase}/environmentsql`, { credentials: 'include' }),
      $fetch(`${config.public.apiBase}/users`, { credentials: 'include' })
    ])
    envs.value = resEnv as any[]
    users.value = resUser as any[]
  } catch(e) { console.error(e) }
}

const assignPort = async () => {
  if (!form.environmentId || !form.userId) return alert('กรุณาเลือกข้อมูลให้ครบถ้วน')
  isLoading.value = true
  result.value = null
  try {
    const res: any = await $fetch(`${config.public.apiBase}/projects`, {
      method: 'POST',
      body: form,
      credentials: 'include'
    })
    result.value = res
    alert('✅ จองสำเร็จ!')
    
    // Reset Form (Clear User only, keep Env for bulk assign)
    form.userId = ''
    selectedUserName.value = '' // ✅ แก้: เติม .value
    searchUserQuery.value = ''  // ✅ แก้: เติม .value
    
  } catch (e: any) {
    alert('Error: ' + (e.data?.details || e.message))
  } finally {
    isLoading.value = false
  }
}

onMounted(loadData)
</script>

<template>
  <div class="max-w-4xl mx-auto pb-20">
    <h2 class="text-3xl font-bold mb-8 text-slate-800">🔌 จอง Port ให้นิสิต</h2>

    <div class="bg-white p-8 rounded-xl shadow-lg border border-gray-100 relative">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
        
        <!-- 1. เลือก Env (Searchable) -->
        <div class="relative">
          <label class="block font-bold mb-2 text-gray-700 text-lg">1. ค้นหา Environment</label>
          <div class="relative">
            <span class="absolute left-3 top-3.5 text-gray-400">🏫</span>
            <input 
              v-model="searchEnvQuery"
              @input="onSearchEnvType"
              @focus="isEnvDropdownOpen = true"
              @blur="closeEnvDropdown"
              type="text" 
              :placeholder="selectedEnvName ? `เลือกแล้ว: ${selectedEnvName}` : 'พิมพ์ชื่อ Env...'"
              class="w-full border-2 border-gray-200 pl-10 p-3 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 outline-none transition cursor-pointer"
              :class="{'border-blue-500 bg-blue-50': selectedEnvName}"
            >
             <button v-if="searchEnvQuery || selectedEnvName" @click="searchEnvQuery=''; form.environmentId=''; selectedEnvName=''" class="absolute right-3 top-3.5 text-gray-400 hover:text-red-500">✕</button>
          </div>

          <!-- Env Dropdown -->
          <div v-if="isEnvDropdownOpen" class="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-60 overflow-y-auto">
            <div v-if="filteredEnvs.length === 0" class="p-4 text-center text-gray-400">ไม่พบ Environment</div>
            <div 
              v-for="e in filteredEnvs" :key="e.id" @click="selectEnv(e)"
              class="p-3 hover:bg-blue-50 cursor-pointer border-b border-gray-100 last:border-0 transition flex justify-between items-center"
            >
              <span class="font-medium text-gray-700">{{ e.name }}</span>
              <span class="text-xs bg-gray-100 text-gray-500 px-2 py-1 rounded">ID: {{ e.id }}</span>
            </div>
          </div>
        </div>

        <!-- 2. เลือกนิสิต (Searchable) -->
        <div class="relative">
          <label class="block font-bold mb-2 text-gray-700 text-lg">2. ค้นหานิสิต</label>
          <div class="relative">
            <span class="absolute left-3 top-3.5 text-gray-400">👤</span>
            <input 
              v-model="searchUserQuery"
              @input="onSearchUserType"
              @focus="isUserDropdownOpen = true"
              @blur="closeUserDropdown"
              type="text" 
              :placeholder="selectedUserName ? `เลือกแล้ว: ${selectedUserName}` : 'พิมพ์ชื่อ หรือ ID...'"
              class="w-full border-2 border-gray-200 pl-10 p-3 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 outline-none transition"
              :class="{'border-blue-500 bg-blue-50': selectedUserName}"
            >
             <button v-if="searchUserQuery || selectedUserName" @click="searchUserQuery=''; form.userId=''; selectedUserName=''" class="absolute right-3 top-3.5 text-gray-400 hover:text-red-500">✕</button>
          </div>

          <!-- User Dropdown -->
          <div v-if="isUserDropdownOpen" class="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-60 overflow-y-auto">
            <div v-if="filteredUsers.length === 0" class="p-4 text-center text-gray-400">ไม่พบข้อมูล</div>
            <div 
              v-for="u in filteredUsers" :key="u.id_users" @click="selectUser(u)"
              class="p-3 hover:bg-blue-50 cursor-pointer border-b border-gray-100 last:border-0 transition flex justify-between items-center"
            >
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center font-bold text-xs text-slate-600">
                  {{ u.username.charAt(0).toUpperCase() }}
                </div>
                <span class="font-medium text-gray-700">{{ u.username }}</span>
              </div>
              <span class="text-xs bg-gray-100 text-gray-500 px-2 py-1 rounded">ID: {{ u.id_users }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 3. เลือกจำนวน -->
      <div class="mb-8 p-6 bg-blue-50 rounded-lg border border-blue-100">
        <label class="block font-bold mb-3 text-blue-800 text-lg">3. ต้องการกี่โปรเจกต์ (Ports)?</label>
        <div class="flex items-center gap-4">
          <input v-model="form.amount" type="number" min="1" max="5" class="border-2 border-blue-200 p-3 rounded-lg w-32 text-center text-2xl font-bold text-blue-600 focus:outline-none">
          <span class="text-gray-500">Ports</span>
        </div>
        <p class="text-sm text-gray-500 mt-2">* ระบบจะหา Port ว่างถัดไปให้โดยอัตโนมัติ (เริ่มที่ 4000)</p>
      </div>

      <button @click="assignPort" :disabled="isLoading || !form.userId || !form.environmentId" class="w-full bg-blue-600 text-white py-4 rounded-xl font-bold text-xl hover:bg-blue-700 transition shadow-lg shadow-blue-200 disabled:bg-gray-400 disabled:shadow-none">
        {{ isLoading ? 'กำลังประมวลผล...' : 'ยืนยันการจอง Port' }}
      </button>
    </div>

    <!-- Result -->
    <div v-if="result" class="mt-8 bg-green-50 border border-green-200 p-8 rounded-xl animate-fade-in-up">
      <h3 class="text-green-800 font-bold text-xl mb-4">🎉 ดำเนินการสำเร็จ</h3>
      <p class="text-gray-600 mb-4">นิสิต <strong>{{ selectedUserName }}</strong> ได้รับ Port ดังนี้:</p>
      <div class="flex flex-wrap gap-4">
        <div v-for="p in result.ports" :key="p" class="bg-white border-2 border-green-400 text-green-700 px-6 py-4 rounded-xl shadow-sm text-center min-w-[120px]">
          <span class="text-xs block text-green-500 uppercase font-bold tracking-wider mb-1">Port</span>
          <span class="text-3xl font-mono font-bold">{{ p }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
.animate-fade-in-up { animation: fadeInUp 0.5s ease-out forwards; }
</style>