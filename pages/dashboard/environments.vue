<script setup lang="ts">
definePageMeta({ layout: 'dashboard' })
const config = useRuntimeConfig()

// --- State ---
const envs = ref<any[]>([])
const teams = ref<any[]>([])
const users = ref<any[]>([]) // โหลด User ทั้งหมดมารอไว้ (เพื่อกรองแสดงผล)
const newEnvName = ref('')
const isCreating = ref(false)

// Modal State
const showModal = ref(false)
const selectedEnv = ref<any>(null)

// --- 1. Load Data ---
const fetchData = async () => {
  try {
    const [resEnv, resTeam, resUser] = await Promise.all([
      $fetch(`${config.public.apiBase}/environmentsql`, { credentials: 'include' }),
      $fetch(`${config.public.apiBase}/teams`, { credentials: 'include' }),
      $fetch(`${config.public.apiBase}/users`, { credentials: 'include' })
    ])
    envs.value = resEnv as any[] || []
    teams.value = resTeam as any[] || []
    users.value = resUser as any[] || []
  } catch (e) { console.error(e) }
}

// --- Helper Functions ---
const getTeamName = (teamId: any) => {
  if (!teamId) return null
  // เช็ค match กับ portainer_team_id ในตาราง teams
  const team = teams.value.find(t => t.portainer_team_id === teamId || t.id === teamId)
  return team ? team.name : 'Unknown Team'
}

// 🔥 Computed: กรอง User เฉพาะคนที่อยู่ใน Team ของ Env ที่เลือก
const usersInSelectedEnv = computed(() => {
  if (!selectedEnv.value || !selectedEnv.value.portainer_team_id) return []
  
  // กรอง User ที่มี portainer_team_id ตรงกับ Env
  return users.value.filter(u => u.portainer_team_id === selectedEnv.value.portainer_team_id)
})

// --- Actions ---
const openDetail = (env: any) => {
  selectedEnv.value = env
  showModal.value = true
}

const closeDetail = () => {
  showModal.value = false
  selectedEnv.value = null
}

const createEnv = async () => {
  if (!newEnvName.value) return
  isCreating.value = true
  try {
    await $fetch(`${config.public.apiBase}/environments`, {
      method: 'POST',
      body: { name: newEnvName.value },
      credentials: 'include'
    })
    alert('✅ สร้างสำเร็จ')
    newEnvName.value = ''
    fetchData()
  } catch (e: any) { alert('Error: ' + (e.data?.details || e.message)) }
  finally { isCreating.value = false }
}

const deleteEnv = async (id: any) => {
  if (!confirm('ยืนยันลบ Environment? (ข้อมูล Project จะหายหมด)')) return
  try {
    await $fetch(`${config.public.apiBase}/environments/${id}`, { 
      method: 'DELETE',
      credentials: 'include'
    })
    fetchData()
  } catch (e: any) { alert('ลบไม่ได้: ' + e.data?.error) }
}

// Link Team (แบบย่อ ใช้ Prompt)
const assignTeam = async (envId: any) => {
    // ในอนาคตทำ Modal เลือกทีมได้ แต่นี่เอาเร็วใช้ Prompt ก่อน
    const teamIdStr = prompt("ใส่ Team ID (Portainer ID) ที่ต้องการผูก:")
    if(!teamIdStr) return
    try {
        await $fetch(`${config.public.apiBase}/environments/${envId}/team`, {
            method: 'PUT',
            body: { teamId: parseInt(teamIdStr) },
            credentials: 'include'
        })
        fetchData()
    } catch(e: any) { alert(e.message) }
}

onMounted(fetchData)
</script>

<template>
  <div class="relative min-h-screen">
    <!-- Header -->
    <h2 class="text-3xl font-bold mb-6 text-slate-800">🏫 Environments Management</h2>

    <!-- Create Bar -->
    <div class="bg-white p-6 rounded-xl shadow-sm mb-8 border border-gray-200">
      <h3 class="font-bold text-lg mb-4 text-gray-700">สร้าง Environment ใหม่</h3>
      <div class="flex gap-4">
        <input 
          v-model="newEnvName" 
          type="text" 
          placeholder="ชื่อ (เช่น Class_2569)" 
          class="flex-1 border p-3 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
          @keyup.enter="createEnv"
        >
        <button 
          @click="createEnv" 
          :disabled="isCreating"
          class="bg-blue-600 text-white px-8 py-3 rounded-lg hover:bg-blue-700 disabled:bg-gray-400 font-bold transition"
        >
          {{ isCreating ? '...' : '+ สร้าง' }}
        </button>
      </div>
    </div>

    <!-- 🟢 Environment Cards Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="env in envs" 
        :key="env.id" 
        class="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition relative flex flex-col"
      >
        <!-- Card Header -->
        <div class="flex justify-between items-start mb-4">
          <div>
            <h3 class="text-xl font-bold text-slate-800">{{ env.name }}</h3>
            <span class="text-xs text-gray-400">ID: {{ env.id }}</span>
          </div>
          <span class="bg-green-100 text-green-700 text-xs px-2 py-1 rounded font-bold">Active</span>
        </div>

        <!-- Team Status Badge -->
        <div class="mb-6">
            <div v-if="env.portainer_team_id" class="inline-flex items-center gap-2 bg-blue-50 border border-blue-100 text-blue-700 px-3 py-1.5 rounded-lg text-sm">
                <span>👥</span>
                <span class="font-semibold">{{ getTeamName(env.portainer_team_id) }}</span>
                <span class="text-xs text-blue-400">(ID: {{ env.portainer_team_id }})</span>
            </div>
            <div v-else class="inline-flex items-center gap-2 bg-gray-100 text-gray-500 px-3 py-1.5 rounded-lg text-sm border border-gray-200">
                <span>⚠️</span> ยังไม่ผูก Team
            </div>
        </div>

        <!-- Spacer -->
        <div class="flex-1"></div>

        <!-- Actions Buttons -->
        <div class="grid grid-cols-2 gap-2 mt-4 pt-4 border-t border-gray-100">
            <!-- ปุ่มดูรายละเอียด (User) -->
            <button 
                @click="openDetail(env)"
                class="flex items-center justify-center gap-2 py-2 bg-slate-800 text-white rounded hover:bg-slate-700 transition text-sm"
            >
                👁️ ดูสมาชิก
            </button>
            
            <!-- ปุ่มผูกทีม -->
            <button 
                @click="assignTeam(env.id)" 
                class="py-2 border border-blue-300 text-blue-600 rounded hover:bg-blue-50 text-sm"
            >
                🔗 ผูกทีม
            </button>
        </div>
        
        <!-- ปุ่มลบ (แยกออกมา) -->
        <button 
            @click="deleteEnv(env.id)" 
            class="w-full mt-2 text-red-400 text-xs hover:text-red-600 hover:underline"
        >
            ลบ Environment นี้
        </button>
      </div>
    </div>

    <!-- 🟡 MODAL Popup: แสดงรายละเอียด User -->
    <div v-if="showModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-xl shadow-2xl w-full max-w-2xl overflow-hidden animate-bounce-in">
            <!-- Modal Header -->
            <div class="bg-slate-800 text-white p-5 flex justify-between items-center">
                <div>
                    <h3 class="text-xl font-bold">🏫 {{ selectedEnv?.name }}</h3>
                    <p class="text-sm text-slate-300 mt-1">
                        Team: {{ getTeamName(selectedEnv?.portainer_team_id) || 'None' }} 
                        (ID: {{ selectedEnv?.portainer_team_id || '-' }})
                    </p>
                </div>
                <button @click="closeDetail" class="text-slate-400 hover:text-white text-2xl">×</button>
            </div>

            <!-- Modal Body -->
            <div class="p-6 max-h-[60vh] overflow-y-auto">
                <h4 class="font-bold text-gray-700 mb-4 flex items-center gap-2">
                    <span>👨‍🎓 รายชื่อนิสิตในทีมนี้</span>
                    <span class="bg-gray-200 text-gray-700 px-2 py-0.5 rounded-full text-xs">{{ usersInSelectedEnv.length }} คน</span>
                </h4>

                <!-- Table User -->
                <table v-if="usersInSelectedEnv.length > 0" class="w-full text-left border-collapse">
                    <thead class="bg-gray-50 text-gray-600 text-sm uppercase">
                        <tr>
                            <th class="p-3 border-b">Avatar</th>
                            <th class="p-3 border-b">Username</th>
                            <th class="p-3 border-b">User ID</th>
                            <th class="p-3 border-b">Role</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="u in usersInSelectedEnv" :key="u.id_users" class="border-b hover:bg-blue-50 transition">
                            <td class="p-3">
                                <div class="w-8 h-8 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xs">
                                    {{ u.username.charAt(0).toUpperCase() }}
                                </div>
                            </td>
                            <td class="p-3 font-medium text-slate-700">{{ u.username }}</td>
                            <td class="p-3 text-gray-500 font-mono text-sm">{{ u.id_users }}</td>
                            <td class="p-3">
                                <span class="bg-gray-100 text-gray-600 px-2 py-1 rounded text-xs">{{ u.role }}</span>
                            </td>
                        </tr>
                    </tbody>
                </table>

                <!-- Empty State -->
                <div v-else class="text-center py-10 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
                    <div class="text-4xl mb-2">🤷‍♂️</div>
                    <p class="text-gray-500">ยังไม่มีนิสิตอยู่ในทีมนี้</p>
                    <p class="text-xs text-gray-400 mt-1">(หรือ Environment นี้ยังไม่ได้ผูกทีม)</p>
                </div>
            </div>

            <!-- Modal Footer -->
            <div class="p-4 border-t bg-gray-50 text-right">
                <button @click="closeDetail" class="px-6 py-2 bg-gray-300 hover:bg-gray-400 rounded text-gray-800 font-medium transition">
                    ปิดหน้าต่าง
                </button>
            </div>
        </div>
    </div>

  </div>
</template>

<style scoped>
@keyframes bounceIn {
  0% { transform: scale(0.9); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}
.animate-bounce-in {
  animation: bounceIn 0.2s ease-out forwards;
}
</style>