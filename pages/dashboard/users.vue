<script setup lang="ts">
definePageMeta({ layout: 'dashboard' })
const config = useRuntimeConfig()

// State
const users = ref<any[]>([])
const selectedUser = ref<any>(null)
const userProjects = ref<any[]>([])
const newUser = reactive({ username: '', password: '' })

// Search State
const searchQuery = ref('')

// 1. โหลดข้อมูล
const fetchUsers = async () => {
  try {
    const res: any = await $fetch(`${config.public.apiBase}/users`, { credentials: 'include' })
    users.value = res
  } catch (e) { console.error(e) }
}

// 🔍 Computed: กรองรายชื่อตามคำค้นหา
const filteredUsers = computed(() => {
  const query = searchQuery.value.toLowerCase()
  if (!query) return users.value
  
  return users.value.filter(u => 
    u.username.toLowerCase().includes(query) || 
    u.id_users.toString().includes(query)
  )
})

// 🔐 Computed: เช็คความถูกต้องรหัสผ่าน
const isPasswordValid = computed(() => {
    return newUser.password.length >= 12
})

// 2. สร้าง User ใหม่ (พร้อม Validation)
const createUser = async () => {
  if (!newUser.username || !newUser.password) return alert('กรุณากรอกข้อมูลให้ครบ')
  if (!isPasswordValid.value) return alert('❌ รหัสผ่านต้องมีความยาวอย่างน้อย 12 ตัวอักษร')

  try {
    await $fetch(`${config.public.apiBase}/users`, {
      method: 'POST',
      body: newUser,
      credentials: 'include'
    })
    alert('✅ สร้างนิสิตสำเร็จ')
    newUser.username = ''
    newUser.password = ''
    fetchUsers()
  } catch (e: any) {
    // ✅ ดึง Error จาก Backend มาแสดง
    alert(e.data?.error || e.data?.message || e.message || "เกิดข้อผิดพลาด");
  }
}

// 3. ลบ User
const deleteUser = async (id: any) => {
  if (!confirm('ยืนยันลบ User นี้? (โปรเจกต์ของเขาจะหายไปด้วย!)')) return
  try {
    await $fetch(`${config.public.apiBase}/users/${id}`, { method: 'DELETE', credentials: 'include' })
    fetchUsers()
    if (selectedUser.value?.id_users === id) {
        selectedUser.value = null
        userProjects.value = []
    }
  } catch (e: any) { 
    // ✅ ดึง Error จาก Backend มาแสดง
    alert(e.data?.error || e.data?.message || e.message || "เกิดข้อผิดพลาด");
  }
}

// 4. เลือก User -> ดู Port
const selectUser = async (u: any) => {
  selectedUser.value = u
  try {
    const res: any = await $fetch(`${config.public.apiBase}/projects?userId=${u.id_users}`, { credentials: 'include' })
    userProjects.value = res.projects || res
  } catch (e) { userProjects.value = [] }
}

// 5. คืน Port
const revokePort = async (projId: any) => {
  if (!confirm('ยืนยันคืน Port นี้? Container ที่ใช้อยู่จะถูกลบ!')) return
  try {
    await $fetch(`${config.public.apiBase}/projects/${projId}`, { method: 'DELETE', credentials: 'include' })
    selectUser(selectedUser.value) 
  } catch(e: any) { 
    // ✅ ดึง Error จาก Backend มาแสดง
    alert(e.data?.error || e.data?.message || e.message || "เกิดข้อผิดพลาด");
  }
}

onMounted(fetchUsers)
</script>

<template>
  <div class="h-[calc(100vh-100px)] flex flex-col">
    <h2 class="text-3xl font-bold mb-6 text-slate-800">👥 User Management</h2>

    <div class="flex gap-6 h-full items-start">
      
      <div class="w-1/3 bg-white rounded-xl shadow-sm flex flex-col border border-gray-200 h-full">
        
        <div class="p-5 border-b bg-slate-50 rounded-t-xl space-y-3">
          <h3 class="font-bold text-slate-700 flex items-center gap-2">
            <span>👤 เพิ่มนิสิตใหม่</span>
          </h3>
          
          <div class="space-y-2">
            <input 
                v-model="newUser.username" 
                placeholder="Username" 
                class="border p-2 rounded w-full text-sm focus:ring-2 focus:ring-blue-500 outline-none"
            >
            <div class="relative">
                <input 
                    v-model="newUser.password" 
                    type="text" 
                    placeholder="Password" 
                    class="border p-2 rounded w-full text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                    :class="{'border-red-300 bg-red-50': newUser.password && !isPasswordValid, 'border-green-300': isPasswordValid}"
                >
                <p v-if="newUser.password && !isPasswordValid" class="text-xs text-red-500 mt-1">
                    ⚠️ ต้องมีอย่างน้อย 12 ตัวอักษร (ปัจจุบัน: {{ newUser.password.length }})
                </p>
                <p v-else class="text-xs text-gray-400 mt-1">
                    * รหัสผ่านต้องยาวอย่างน้อย 12 ตัวอักษร
                </p>
            </div>
          </div>

          <button 
            @click="createUser" 
            :disabled="!isPasswordValid || !newUser.username"
            class="w-full bg-blue-600 text-white text-sm py-2 rounded hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
          >
            + ยืนยันสร้าง
          </button>
        </div>
        
        <div class="p-3 border-b bg-white sticky top-0">
            <div class="relative">
                <span class="absolute left-3 top-2.5 text-gray-400 text-xs">🔍</span>
                <input 
                    v-model="searchQuery" 
                    placeholder="ค้นหาชื่อ หรือ ID..." 
                    class="w-full border border-gray-200 pl-8 p-2 rounded text-sm bg-gray-50 focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none transition"
                >
                <span v-if="searchQuery" class="absolute right-3 top-2.5 text-xs text-gray-400 cursor-pointer hover:text-red-500" @click="searchQuery=''">✕</span>
            </div>
        </div>

        <div class="flex-1 overflow-y-auto p-2 scrollbar-thin">
          <div v-if="filteredUsers.length === 0" class="text-center py-8 text-gray-400 text-sm">
            ไม่พบข้อมูลที่ค้นหา
          </div>

          <div 
            v-for="u in filteredUsers" :key="u.id_users" 
            @click="selectUser(u)"
            class="p-3 rounded-lg cursor-pointer mb-1 flex justify-between items-center group transition border"
            :class="selectedUser?.id_users === u.id_users ? 'bg-blue-50 border-blue-400 shadow-sm' : 'hover:bg-gray-50 border-transparent'"
          >
            <div class="flex items-center gap-3 overflow-hidden">
                <div class="w-8 h-8 rounded-full flex-shrink-0 flex items-center justify-center font-bold text-xs shadow-sm"
                     :class="selectedUser?.id_users === u.id_users ? 'bg-blue-500 text-white' : 'bg-slate-200 text-slate-600'">
                    {{ u.username.charAt(0).toUpperCase() }}
                </div>
                <div class="truncate">
                    <div class="font-medium text-slate-700 text-sm truncate">{{ u.username }}</div>
                    <div class="text-xs text-gray-400">ID: {{ u.id_users }}</div>
                </div>
            </div>
            
            <button 
                @click.stop="deleteUser(u.id_users)" 
                class="text-xs text-gray-300 hover:text-red-500 hover:bg-red-50 px-2 py-1 rounded transition opacity-0 group-hover:opacity-100"
                title="ลบผู้ใช้"
            >
                🗑️
            </button>
          </div>
        </div>
      </div>

      <div class="w-2/3 bg-white rounded-xl shadow-sm p-6 border border-gray-200 h-full overflow-y-auto">
        <div v-if="selectedUser" class="animate-fade-in">
          <div class="flex justify-between items-center mb-6 pb-4 border-b">
             <div>
                 <h3 class="text-2xl font-bold text-blue-600">{{ selectedUser.username }}</h3>
                 <p class="text-xs text-gray-400 mt-1 bg-gray-100 inline-block px-2 py-1 rounded">System ID: {{ selectedUser.id_users }}</p>
                 <p class="text-xs text-gray-400 mt-1 ml-2 bg-gray-100 inline-block px-2 py-1 rounded">Portainer UID: {{ selectedUser.portainer_user_id }}</p>
             </div>
             <div class="text-right bg-blue-50 px-4 py-2 rounded-lg">
                 <div class="text-3xl font-bold text-slate-800">{{ userProjects.length }}</div>
                 <div class="text-xs text-blue-500 uppercase font-bold tracking-wider">Active Ports</div>
             </div>
          </div>
         
          <div v-if="userProjects.length > 0" class="grid grid-cols-1 xl:grid-cols-2 gap-4">
            <div v-for="p in userProjects" :key="p.project_id" class="border border-gray-200 p-5 rounded-xl bg-gray-50 relative hover:shadow-md transition group">
              <button @click="revokePort(p.project_id)" class="absolute top-3 right-3 text-gray-400 hover:text-red-600 bg-white w-8 h-8 rounded-full shadow-sm flex items-center justify-center transition opacity-0 group-hover:opacity-100" title="คืน Port (ลบ Project)">
                🗑️
              </button>
              
              <div class="flex items-center gap-2 mb-3">
                <span class="text-[10px] font-bold bg-green-100 text-green-700 px-2 py-0.5 rounded uppercase tracking-wide">Running</span>
                <span class="text-[10px] text-gray-400 font-mono">PID: {{ p.project_id }}</span>
              </div>

              <div class="flex justify-between items-end">
                  <div>
                      <div class="text-xs text-gray-500 uppercase font-semibold mb-1">Port Number</div>
                      <div class="text-4xl font-mono font-bold text-slate-700 tracking-tighter">{{ p.port }}</div>
                  </div>
                  <div class="text-right">
                      <div class="text-xs text-gray-500 mb-1">Environment</div>
                      <div class="font-medium text-blue-600 bg-blue-100 px-2 py-1 rounded inline-block text-xs">{{ p.environment_name }}</div>
                  </div>
              </div>
            </div>
          </div>
          
          <div v-else class="flex flex-col items-center justify-center h-64 text-gray-400 bg-slate-50 rounded-xl border-2 border-dashed border-slate-200">
            <div class="text-5xl mb-3 opacity-50">📭</div>
            <p>นิสิตคนนี้ยังไม่มีโปรเจกต์</p>
            <p class="text-xs mt-2 text-gray-400">ไปที่เมนู "Port Reservation" เพื่อจองให้</p>
          </div>
        </div>
        
        <div v-else class="h-full flex flex-col items-center justify-center text-gray-300">
          <div class="text-8xl mb-6 opacity-20">👥</div>
          <p class="text-xl font-medium text-gray-400">เลือกนิสิตจากรายการฝั่งซ้าย</p>
          <p class="text-sm">เพื่อดูรายละเอียดการจอง Port</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.scrollbar-thin::-webkit-scrollbar { width: 6px; }
.scrollbar-thin::-webkit-scrollbar-track { background: transparent; }
.scrollbar-thin::-webkit-scrollbar-thumb { background-color: #e2e8f0; border-radius: 20px; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }
.animate-fade-in { animation: fadeIn 0.3s ease-out; }
</style>