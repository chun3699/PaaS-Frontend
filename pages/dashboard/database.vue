<script setup lang="ts">
definePageMeta({ layout: 'dashboard' })

// เรียกใช้ Runtime Config ที่คุณตั้งไว้ใน nuxt.config.ts
const config = useRuntimeConfig()
const API_URL = config.public.apiBase // ดึงค่า http://10.33.4.47:3000/api มาใช้

// --- State ---
const users = ref<any[]>([])
const loading = ref(false)
const searchQuery = ref('')

// Modal State
const showModal = ref(false)
const dbResult = ref<any>({})

// --- 1. Load Data ---
const fetchUsers = async () => {
  loading.value = true
  try {
    // ใช้ API_URL จาก config
    const res = await $fetch(`${API_URL}/users`, { credentials: 'include' })
    users.value = res as any[] || []
  } catch (e) {
    console.error('Fetch error:', e)
  } finally {
    loading.value = false
  }
}

// 🔥 Computed: กรอง User ตามคำค้นหา
const filteredUsers = computed(() => {
  if (!searchQuery.value) return users.value
  const lowerSearch = searchQuery.value.toLowerCase()
  return users.value.filter(u => 
    u.username.toLowerCase().includes(lowerSearch) || 
    String(u.id_users).includes(lowerSearch)
  )
})

// --- Actions ---

// สร้าง Database
const createDB = async (user: any) => {
  if (!confirm(`ยืนยันการสร้าง Database ให้ ${user.username}?`)) return
  
  try {
    const res: any = await $fetch(`${API_URL}/sql/create-db`, {
      method: 'POST',
      body: { username: user.username },
      credentials: 'include'
    })

    if (res.success) {
      dbResult.value = res.credentials
      showModal.value = true
      
      // Update State ทันที
      const target = users.value.find(u => u.id_users === user.id_users)
      if (target) target.mysql = 1
    }
  } catch (e: any) {
    alert('Error: ' + (e.data?.message || e.message))
  }
}

// ลบ Database
const deleteDB = async (user: any) => {
  if (!confirm(`⚠️ อันตราย!\nต้องการลบ Database ของ "${user.username}" ใช่หรือไม่?\nข้อมูลจะหายกู้คืนไม่ได้!`)) return

  try {
    const res: any = await $fetch(`${API_URL}/sql/delete-db`, {
      method: 'DELETE',
      body: { username: user.username },
      credentials: 'include'
    })

    if (res.success) {
      alert(`ลบ Database ของ ${user.username} เรียบร้อยแล้ว`)
      // Update State ทันที
      const target = users.value.find(u => u.id_users === user.id_users)
      if (target) target.mysql = 0
    }
  } catch (e: any) {
    alert('Error: ' + (e.data?.message || e.message))
  }
}

const closeModal = () => {
  showModal.value = false
  dbResult.value = {}
}

onMounted(fetchUsers)
</script>

<template>
  <div class="relative min-h-screen fade-in">
    <h2 class="text-3xl font-bold mb-6 text-slate-800 flex items-center gap-3">
        🗄️ Database Management
    </h2>

    <div class="bg-white p-6 rounded-xl shadow-sm mb-8 border border-gray-200">
      <div class="flex justify-between items-center mb-4">
        <h3 class="font-bold text-lg text-gray-700">จัดการฐานข้อมูลนิสิต</h3>
        <button @click="fetchUsers" class="text-sm text-blue-600 hover:underline flex items-center gap-1 transition-colors">
            🔄 Refresh Data
        </button>
      </div>
      
      <div class="flex gap-4">
        <div class="relative flex-1">
            <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-400">🔍</span>
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="ค้นหาชื่อนิสิต หรือ ID..." 
              class="w-full border p-3 pl-10 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-slate-700 transition shadow-sm focus:shadow-md"
            >
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="user in filteredUsers" 
        :key="user.id_users" 
        class="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition duration-200 relative flex flex-col group"
      >
        <div class="flex justify-between items-start mb-4">
          <div class="flex items-center gap-3">
             <div class="w-10 h-10 rounded-full bg-slate-100 text-slate-600 flex items-center justify-center font-bold text-sm">
                {{ user.username.substring(0, 2).toUpperCase() }}
             </div>
             <div>
                <h3 class="text-lg font-bold text-slate-800 leading-tight">{{ user.username }}</h3>
                <span class="text-xs text-gray-400 font-mono">ID: {{ user.id_users }}</span>
             </div>
          </div>
          <span class="bg-gray-100 text-gray-500 text-xs px-2 py-1 rounded font-bold">{{ user.role === 1 ? 'Admin' : 'Student' }}</span>
        </div>

        <div class="mb-6">
            <div v-if="user.mysql === 1" class="inline-flex items-center gap-2 bg-green-50 border border-green-100 text-green-700 px-3 py-2 rounded-lg text-sm w-full animate-pulse-once">
                <span>✅</span>
                <div class="flex flex-col">
                    <span class="font-semibold text-xs uppercase tracking-wide">Database Active</span>
                    <span class="text-xs font-mono text-green-600">db_{{ user.username }}</span>
                </div>
            </div>
            <div v-else class="inline-flex items-center gap-2 bg-gray-50 text-gray-400 px-3 py-2 rounded-lg text-sm border border-gray-200 w-full">
                <span>⚪</span> ยังไม่มี Database
            </div>
        </div>

        <div class="flex-1"></div>

        <div class="grid grid-cols-1 gap-2 mt-4 pt-4 border-t border-gray-100">
            <button 
                v-if="user.mysql === 0"
                @click="createDB(user)"
                class="flex items-center justify-center gap-2 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-bold shadow-sm hover:shadow"
            >
                ⚡ สร้าง Database
            </button>
            
            <button 
                v-else
                @click="deleteDB(user)"
                class="flex items-center justify-center gap-2 py-2.5 border border-red-200 text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition font-medium"
            >
                🗑️ ลบ Database
            </button>
        </div>
      </div>
    </div>

    <div v-if="filteredUsers.length === 0 && !loading" class="text-center py-20 text-gray-400">
        ไม่พบข้อมูลนิสิตที่ค้นหา
    </div>
    <div v-if="loading" class="text-center py-20 text-blue-500">
        กำลังโหลดข้อมูล...
    </div>

    <div v-if="showModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
        <div class="bg-white rounded-xl shadow-2xl w-full max-w-md overflow-hidden animate-bounce-in">
            <div class="bg-slate-800 text-white p-5 flex justify-between items-center">
                <h3 class="text-xl font-bold flex items-center gap-2">
                    ✅ สร้างสำเร็จ
                </h3>
                <button @click="closeModal" class="text-slate-400 hover:text-white text-2xl transition">×</button>
            </div>

            <div class="p-6">
                <p class="text-gray-600 mb-4 text-sm">ส่งข้อมูลนี้ให้นิสิตเพื่อใช้ในการเชื่อมต่อฐานข้อมูล</p>
                
                <div class="bg-gray-50 p-4 rounded-lg border border-gray-200 space-y-3 text-sm font-mono select-text">
                    <div class="flex justify-between border-b pb-2">
                        <span class="text-gray-500">Host IP:</span>
                        <span class="font-bold text-slate-800">{{ dbResult.host }}</span>
                    </div>
                    <div class="flex justify-between border-b pb-2">
                        <span class="text-gray-500">Port:</span>
                        <span class="font-bold text-slate-800">{{ dbResult.port }}</span>
                    </div>
                    <div class="flex justify-between border-b pb-2">
                        <span class="text-gray-500">Database:</span>
                        <span class="font-bold text-blue-600">{{ dbResult.database }}</span>
                    </div>
                    <div class="flex justify-between border-b pb-2">
                        <span class="text-gray-500">Username:</span>
                        <span class="font-bold text-slate-800">{{ dbResult.username }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Password:</span>
                        <span class="font-bold text-red-600 bg-red-50 px-2 rounded">{{ dbResult.password }}</span>
                    </div>
                </div>

                <div class="mt-6">
                    <button @click="closeModal" class="w-full py-3 bg-slate-800 hover:bg-slate-700 rounded-lg text-white font-medium transition shadow-lg">
                        ตกลง / ปิดหน้าต่าง
                    </button>
                </div>
            </div>
        </div>
    </div>

  </div>
</template>

<style scoped>
@keyframes bounceIn {
  0% { transform: scale(0.95); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}
.animate-bounce-in {
  animation: bounceIn 0.2s cubic-bezier(0.18, 0.89, 0.32, 1.28) forwards;
}

.fade-in {
  animation: fadeIn 0.4s ease-out;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>