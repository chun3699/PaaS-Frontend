<script setup lang="ts">
definePageMeta({ layout: 'dashboard' })

const config = useRuntimeConfig()
const API_URL = config.public.apiBase

// --- State ---
const users = ref<any[]>([])
const loading = ref(false)
const searchQuery = ref('')
const selectedIds = ref<Set<number>>(new Set()) // เก็บ ID ของคนที่ติ๊กถูก
const processingIds = ref<Set<number>>(new Set()) // เก็บ ID ของคนที่กำลังหมุนติ้วๆ

// --- 1. Load Data ---
const fetchUsers = async () => {
  loading.value = true
  selectedIds.value.clear() // ล้าง Selection เมื่อโหลดใหม่
  try {
    const res = await $fetch(`${API_URL}/users`, { credentials: 'include' })
    users.value = res as any[] || []
  } catch (e) {
    console.error('Fetch error:', e)
  } finally {
    loading.value = false
  }
}

// --- Computed ---
// กรอง User ตามคำค้นหา
const filteredUsers = computed(() => {
  if (!searchQuery.value) return users.value
  const lowerSearch = searchQuery.value.toLowerCase()
  return users.value.filter(u => 
    u.username.toLowerCase().includes(lowerSearch) || 
    String(u.id_users).includes(lowerSearch)
  )
})

// เช็คว่าเลือกครบทุกคนในหน้าปัจจุบันไหม
const isAllSelected = computed(() => {
  return filteredUsers.value.length > 0 && filteredUsers.value.every(u => selectedIds.value.has(u.id_users))
})

// --- Selection Logic ---
const toggleSelectAll = () => {
  if (isAllSelected.value) {
    // ถ้าเลือกครบแล้ว -> ยกเลิกทั้งหมด
    selectedIds.value.clear()
  } else {
    // ถ้ายังไม่ครบ -> เลือกทุกคนที่โชว์อยู่ (Filtered)
    filteredUsers.value.forEach(u => selectedIds.value.add(u.id_users))
  }
}

const toggleSelection = (id: number) => {
  if (selectedIds.value.has(id)) selectedIds.value.delete(id)
  else selectedIds.value.add(id)
}

// --- Bulk Actions ---
const bulkAction = async (action: 'create' | 'delete') => {
  const targetIds = Array.from(selectedIds.value)
  if (targetIds.length === 0) return

  // กรองเฉพาะคนที่มีเงื่อนไขตรง (เช่น จะสร้าง ก็ต้องเลือกเฉพาะคนที่ยังไม่มี)
  const usersToProcess = users.value.filter(u => 
    selectedIds.value.has(u.id_users) && 
    (action === 'create' ? !u.mysql : u.mysql) // mysql: 0 or 1 works as boolean
  )

  if (usersToProcess.length === 0) {
    alert(action === 'create' ? 'คนที่เลือกมี Database หมดแล้ว' : 'คนที่เลือกยังไม่มี Database')
    return
  }

  const confirmMsg = action === 'create' 
    ? `ยืนยันสร้าง Database ให้ ${usersToProcess.length} คนที่เลือก?`
    : `⚠️ อันตราย! ยืนยันลบ Database ของ ${usersToProcess.length} คนที่เลือก?`

  if (!confirm(confirmMsg)) return

  // เริ่มกระบวนการ Loop ยิง API
  for (const user of usersToProcess) {
    processingIds.value.add(user.id_users) // เปิด Loading รายคน
    try {
      await $fetch(`${API_URL}/sql/${action}-db`, {
        method: action === 'create' ? 'POST' : 'DELETE',
        body: { username: user.username },
        credentials: 'include'
      })
      
      // Update State ใน Frontend ทันที (ไม่ต้องโหลดใหม่)
      const target = users.value.find(u => u.id_users === user.id_users)
      if (target) target.mysql = action === 'create' ? 1 : 0
      
    } catch (e) {
      console.error(`Error processing ${user.username}:`, e)
    } finally {
      processingIds.value.delete(user.id_users)
    }
  }

  alert('ดำเนินการเสร็จสิ้น')
  selectedIds.value.clear() // เคลียร์ Checkbox
}

// --- Individual Action ---
const singleAction = async (user: any, action: 'create' | 'delete') => {
  if (action === 'delete' && !confirm(`ยืนยันลบ Database ของ ${user.username}?`)) return
  
  processingIds.value.add(user.id_users)
  try {
    await $fetch(`${API_URL}/sql/${action}-db`, {
      method: action === 'create' ? 'POST' : 'DELETE',
      body: { username: user.username },
      credentials: 'include'
    })
    
    // Update State
    const target = users.value.find(u => u.id_users === user.id_users)
    if (target) target.mysql = action === 'create' ? 1 : 0
    
    // ถ้าสร้างสำเร็จ แจ้งเตือนเล็กน้อย
    if (action === 'create') alert(`✅ สร้างให้ ${user.username} สำเร็จ! ใช้รหัสเดิม Login ได้เลย`)

  } catch (e: any) {
    alert('Error: ' + (e.data?.message || e.message))
  } finally {
    processingIds.value.delete(user.id_users)
  }
}

onMounted(fetchUsers)
</script>

<template>
  <div class="relative min-h-screen">
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
      <h2 class="text-3xl font-bold text-slate-800 flex items-center gap-3">
        🗄️ Database Management
      </h2>
      <div class="flex gap-2">
         <div class="bg-blue-50 text-blue-700 px-4 py-2 rounded-lg font-medium text-sm flex items-center">
            <span class="mr-2">🔌 Host:</span>
            <span class="font-mono font-bold">{{ config.public.apiBase ? '10.33.4.47' : 'localhost' }}</span>
         </div>
         <div class="bg-blue-50 text-blue-700 px-4 py-2 rounded-lg font-medium text-sm flex items-center">
            <span class="mr-2">🚪 Port:</span>
            <span class="font-mono font-bold">3306</span>
         </div>
      </div>
    </div>

    <div class="bg-white p-4 rounded-xl shadow-sm border border-gray-200 mb-6 sticky top-0 z-10">
      <div class="flex flex-col md:flex-row justify-between items-center gap-4">
        
        <div class="relative w-full md:w-96">
            <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-400">🔍</span>
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="ค้นหาชื่อนิสิต..." 
              class="w-full border p-2.5 pl-10 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-slate-700 bg-gray-50"
            >
        </div>

        <div class="flex gap-3 w-full md:w-auto justify-end">
            <transition name="fade">
              <div v-if="selectedIds.size > 0" class="flex gap-2 items-center mr-4 border-r pr-4">
                <span class="text-sm font-bold text-gray-600">{{ selectedIds.size }} selected</span>
                
                <button 
                  @click="bulkAction('create')"
                  class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm font-bold flex items-center gap-2 shadow-sm"
                >
                  ⚡ Create All
                </button>
                
                <button 
                  @click="bulkAction('delete')"
                  class="bg-red-50 text-red-600 border border-red-200 px-4 py-2 rounded-lg hover:bg-red-100 text-sm font-bold flex items-center gap-2"
                >
                  🗑️ Delete All
                </button>
              </div>
            </transition>

            <button @click="fetchUsers" class="text-gray-500 hover:text-blue-600 p-2 rounded-full hover:bg-gray-100 transition">
                🔄
            </button>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead class="bg-slate-50 text-slate-600 text-xs uppercase tracking-wider font-bold">
            <tr>
              <th class="p-4 w-12 text-center">
                <input type="checkbox" :checked="isAllSelected" @change="toggleSelectAll" class="w-4 h-4 rounded text-blue-600 focus:ring-blue-500 cursor-pointer">
              </th>
              <th class="p-4 w-16">Avatar</th>
              <th class="p-4">Username</th>
              <th class="p-4 w-40 text-center">Status</th>
              <th class="p-4 w-48 font-mono text-xs">DB Name</th>
              <th class="p-4 w-40 text-center">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="user in filteredUsers" :key="user.id_users" class="hover:bg-blue-50 transition duration-150 group">
              
              <td class="p-4 text-center">
                 <input type="checkbox" :checked="selectedIds.has(user.id_users)" @change="toggleSelection(user.id_users)" class="w-4 h-4 rounded text-blue-600 focus:ring-blue-500 cursor-pointer">
              </td>

              <td class="p-4">
                 <div class="w-8 h-8 rounded-full bg-slate-100 text-slate-500 flex items-center justify-center font-bold text-xs border border-slate-200">
                    {{ user.username.substring(0, 2).toUpperCase() }}
                 </div>
              </td>

              <td class="p-4">
                 <div class="font-bold text-slate-700">{{ user.username }}</div>
                 <div class="text-xs text-gray-400 font-mono">ID: {{ user.id_users }}</div>
              </td>

              <td class="p-4 text-center">
                 <span v-if="user.mysql" class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 border border-green-200">
                    <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
                    Active
                 </span>
                 <span v-else class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-400 border border-gray-200">
                    None
                 </span>
              </td>

              <td class="p-4 text-xs font-mono text-slate-500">
                 <span v-if="user.mysql" class="text-blue-600">db_{{ user.username }}</span>
                 <span v-else class="text-gray-300">-</span>
              </td>

              <td class="p-4 text-center">
                 <div v-if="processingIds.has(user.id_users)" class="text-blue-500 text-xs animate-pulse font-bold">
                    Processing...
                 </div>
                 <div v-else>
                    <button 
                        v-if="!user.mysql"
                        @click="singleAction(user, 'create')"
                        class="text-xs bg-blue-600 hover:bg-blue-700 text-white px-3 py-1.5 rounded shadow-sm transition flex items-center gap-1 mx-auto"
                    >
                        ⚡ Create
                    </button>
                    <button 
                        v-else
                        @click="singleAction(user, 'delete')"
                        class="text-xs border border-red-200 text-red-500 hover:bg-red-50 px-3 py-1.5 rounded transition flex items-center gap-1 mx-auto"
                    >
                        🗑️ Delete
                    </button>
                 </div>
              </td>

            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="filteredUsers.length === 0 && !loading" class="text-center py-12 text-gray-400 border-t">
          ไม่พบข้อมูลที่ค้นหา
      </div>
      <div v-if="loading" class="text-center py-12 text-blue-500 border-t">
          กำลังโหลดข้อมูล...
      </div>
    </div>
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>