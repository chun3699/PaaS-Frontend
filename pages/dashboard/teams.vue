<script setup lang="ts">
definePageMeta({ layout: 'dashboard' })
const config = useRuntimeConfig()

// State ข้อมูลหลัก
const teams = ref<any[]>([])
const allUsers = ref<any[]>([]) // User ทั้งหมดในระบบ
const selectedTeam = ref<any>(null)
const teamMembers = ref<any[]>([]) // สมาชิกในทีมที่เลือกอยู่

// Form สร้างทีม
const newTeamName = ref('')

// --- 🔍 ส่วนค้นหาเพื่อเพิ่มสมาชิก (Searchable Dropdown) ---
const searchQuery = ref('')
const isDropdownOpen = ref(false)
const userToAddId = ref('')      // เก็บ ID ที่เลือก
const userToAddName = ref('')    // เก็บชื่อที่เลือก (เพื่อโชว์ใน Input)

// Computed: กรองรายชื่อคนที่จะเพิ่ม (Candidates)
// 1. ต้องไม่อยู่ในทีมนี้อยู่แล้ว
// 2. ชื่อต้องตรงกับคำค้นหา
const filteredCandidates = computed(() => {
  // กรองคนที่มีอยู่แล้วออกก่อน (คนที่มี Team ID ตรงกับทีมนี้)
  const availableUsers = allUsers.value.filter(u => u.portainer_team_id !== selectedTeam.value?.portainer_team_id)

  const query = searchQuery.value.toLowerCase()
  if (!query) return availableUsers

  // กรองตามคำค้น
  return availableUsers.filter(u => 
    u.username.toLowerCase().includes(query) || 
    u.id_users.toString().includes(query)
  )
})

// Action: เลือกคนจาก Dropdown
const selectCandidate = (user: any) => {
  userToAddId.value = user.portainer_user_id // ใช้ Portainer ID สำหรับยิง API
  userToAddName.value = user.username
  searchQuery.value = ''
  isDropdownOpen.value = false
}

// Action: พิมพ์ค้นหา
const onSearchType = () => {
  if (!isDropdownOpen.value) isDropdownOpen.value = true
  if (userToAddId.value) { // ถ้าพิมพ์ใหม่ ให้เคลียร์ค่าเดิม
      userToAddId.value = ''
      userToAddName.value = ''
  }
}

const closeDropdown = () => { setTimeout(() => { isDropdownOpen.value = false }, 200) }
// -----------------------------------------------------------


// 1. โหลดข้อมูลทีม และ User ทั้งหมด
const loadData = async () => {
  try {
    const [resTeams, resUsers] = await Promise.all([
      $fetch(`${config.public.apiBase}/teams`, { credentials: 'include' }),
      $fetch(`${config.public.apiBase}/users`, { credentials: 'include' })
    ])
    teams.value = resTeams as any[]
    allUsers.value = resUsers as any[]
  } catch (e) { console.error(e) }
}

// 2. เลือกทีม -> โหลดสมาชิก
const selectTeam = async (team: any) => {
  selectedTeam.value = team
  // กรอง User จาก List ที่โหลดมาแล้ว
  teamMembers.value = allUsers.value.filter((u: any) => u.portainer_team_id === team.portainer_team_id)
  
  // Reset Form เพิ่มคน
  userToAddId.value = ''
  userToAddName.value = ''
  searchQuery.value = ''
}

// 3. สร้างทีมใหม่
const createTeam = async () => {
  if (!newTeamName.value) return
  try {
    await $fetch(`${config.public.apiBase}/teams`, {
      method: 'POST',
      body: { name: newTeamName.value },
      credentials: 'include'
    })
    alert('✅ สร้างทีมสำเร็จ')
    newTeamName.value = ''
    loadData()
  } catch (e: any) { alert(e.message) }
}

// 4. ลบทีม
const deleteTeam = async (id: any) => {
  if (!confirm('ยืนยันลบทีม? สมาชิกในทีมจะหลุดออกจากทีมทั้งหมด!')) return
  try {
    await $fetch(`${config.public.apiBase}/teams/${id}`, { method: 'DELETE', credentials: 'include' })
    loadData()
    selectedTeam.value = null
  } catch (e: any) { alert(e.message) }
}

// 5. เพิ่มสมาชิกเข้าทีม (Submit)
const addMember = async () => {
  if (!userToAddId.value) return alert('กรุณาเลือกนิสิตก่อน')
  
  try {
    await $fetch(`${config.public.apiBase}/users/team`, {
      method: 'PUT',
      body: {
        userId: userToAddId.value, 
        teamId: selectedTeam.value.portainer_team_id
      },
      credentials: 'include'
    })
    
    // อัปเดตข้อมูล Local
    await loadData() // โหลด User ใหม่ (เพราะ status team เปลี่ยน)
    
    // อัปเดตสมาชิกในหน้านี้ทันที (ต้องรอ loadData เสร็จก่อน)
    if (selectedTeam.value) {
        teamMembers.value = allUsers.value.filter((u: any) => u.portainer_team_id === selectedTeam.value.portainer_team_id)
    }
    
    // Reset Form
    userToAddId.value = ''
    userToAddName.value = ''
    alert('✅ เพิ่มสมาชิกสำเร็จ')
  } catch (e: any) {
    alert('Error: ' + (e.data?.error || e.message))
  }
}

// 6. เตะออกจากทีม
const removeMember = async (userId: any) => {
  if (!confirm('เอานิสิตคนนี้ออกจากทีม?')) return
  try {
    await $fetch(`${config.public.apiBase}/users/team`, {
      method: 'DELETE',
      body: { userId: userId },
      credentials: 'include'
    })
    
    await loadData()
    // Refresh Members List
    if (selectedTeam.value) {
        teamMembers.value = allUsers.value.filter((u: any) => u.portainer_team_id === selectedTeam.value.portainer_team_id)
    }
  } catch (e: any) { alert('Error: ' + e.message) }
}

onMounted(loadData)
</script>

<template>
  <div class="h-[calc(100vh-100px)] flex flex-col">
    <h2 class="text-3xl font-bold mb-6 text-slate-800">🤝 Manage Teams</h2>

    <div class="flex gap-6 h-full items-start">
      
      <!-- 🟢 Left: Team List -->
      <div class="w-1/3 bg-white rounded-xl shadow-sm flex flex-col border border-gray-200 h-full">
        <!-- Create -->
        <div class="p-4 border-b bg-gray-50 rounded-t-xl flex gap-2">
          <input 
            v-model="newTeamName" 
            placeholder="ชื่อทีมใหม่..." 
            class="flex-1 border p-2 rounded text-sm focus:ring-2 focus:ring-blue-500 outline-none"
            @keyup.enter="createTeam"
          >
          <button @click="createTeam" class="bg-blue-600 text-white px-3 py-2 rounded text-sm hover:bg-blue-700 whitespace-nowrap">+ สร้าง</button>
        </div>

        <!-- List -->
        <div class="flex-1 overflow-y-auto p-2">
          <div 
            v-for="team in teams" 
            :key="team.id_team"
            @click="selectTeam(team)"
            class="p-3 rounded-lg cursor-pointer mb-1 flex justify-between items-center group transition"
            :class="selectedTeam?.id_team === team.id_team ? 'bg-blue-50 border border-blue-300' : 'hover:bg-gray-50 border border-transparent'"
          >
            <div>
              <span class="font-bold text-gray-700 block">{{ team.name }}</span>
              <span class="text-xs text-gray-400">PID: {{ team.portainer_team_id }}</span>
            </div>
            <button @click.stop="deleteTeam(team.id_team)" class="text-xs text-red-400 opacity-0 group-hover:opacity-100 hover:text-red-600 bg-red-50 px-2 py-1 rounded">ลบ</button>
          </div>
        </div>
      </div>

      <!-- 🔵 Right: Team Members & Add Member -->
      <div class="w-2/3 bg-white rounded-xl shadow-sm p-6 border border-gray-200 h-full flex flex-col">
        
        <div v-if="selectedTeam" class="h-full flex flex-col">
          <!-- Header & Add Member Section -->
          <div class="mb-6 pb-6 border-b">
             <div class="flex justify-between items-end mb-4">
                 <div>
                     <h3 class="text-2xl font-bold text-blue-600">{{ selectedTeam.name }}</h3>
                     <p class="text-sm text-gray-500">สมาชิกปัจจุบัน: {{ teamMembers.length }} คน</p>
                 </div>
             </div>
             
             <!-- 🔍 Searchable Add Member Box -->
             <div class="bg-blue-50 p-4 rounded-lg border border-blue-100 relative">
                <label class="block text-sm font-bold text-blue-800 mb-2">เพิ่มสมาชิกเข้าทีมนี้</label>
                <div class="flex gap-2 relative">
                    <!-- Search Input -->
                    <div class="relative flex-1">
                        <span class="absolute left-3 top-2.5 text-gray-400">🔍</span>
                        <input 
                            v-model="searchQuery"
                            @input="onSearchType"
                            @focus="isDropdownOpen = true"
                            @blur="closeDropdown"
                            type="text" 
                            :placeholder="userToAddName ? `เลือกแล้ว: ${userToAddName}` : 'พิมพ์ชื่อ หรือ ID เพื่อค้นหา...'"
                            class="w-full border border-gray-300 pl-9 p-2 rounded bg-white focus:ring-2 focus:ring-blue-500 outline-none text-sm h-10"
                            :class="{'border-blue-500 bg-blue-50': userToAddName}"
                        >
                        <!-- Clear Button -->
                        <button v-if="searchQuery || userToAddName" @click="searchQuery=''; userToAddName=''; userToAddId=''" class="absolute right-3 top-2.5 text-gray-400 hover:text-red-500">✕</button>

                        <!-- Dropdown List -->
                        <div v-if="isDropdownOpen" class="absolute top-full left-0 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-xl max-h-48 overflow-y-auto z-10">
                            <div v-if="filteredCandidates.length === 0" class="p-3 text-center text-gray-400 text-sm">
                                ไม่พบข้อมูล (หรืออยู่ในทีมนี้แล้ว)
                            </div>
                            <div 
                                v-for="u in filteredCandidates" 
                                :key="u.id_users" 
                                @click="selectCandidate(u)"
                                class="p-2 hover:bg-blue-50 cursor-pointer border-b border-gray-100 last:border-0 flex justify-between items-center text-sm"
                            >
                                <span class="font-medium text-gray-700">{{ u.username }}</span>
                                <span class="text-xs bg-gray-100 text-gray-500 px-2 py-0.5 rounded flex items-center gap-1">
                                    <span v-if="u.portainer_team_id" class="text-orange-500" title="จะถูกย้ายมาจากทีมอื่น">⚠️ ย้ายทีม</span>
                                    ID: {{ u.id_users }}
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Add Button -->
                    <button 
                        @click="addMember" 
                        :disabled="!userToAddId"
                        class="bg-blue-600 text-white px-6 rounded hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed font-bold text-sm h-10"
                    >
                        ยืนยันเพิ่ม
                    </button>
                </div>
             </div>
          </div>

          <!-- Members Table -->
          <div class="flex-1 overflow-y-auto">
            <table v-if="teamMembers.length > 0" class="w-full text-left border-collapse">
              <thead class="bg-gray-50 text-gray-600 text-xs uppercase sticky top-0">
                <tr>
                  <th class="p-3">User</th>
                  <th class="p-3">System ID</th>
                  <th class="p-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="member in teamMembers" :key="member.id_users" class="border-b hover:bg-gray-50">
                  <td class="p-3 font-medium text-slate-700 flex items-center gap-2">
                    <div class="w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-500">{{ member.username.charAt(0).toUpperCase() }}</div>
                    {{ member.username }}
                  </td>
                  <td class="p-3 text-gray-500 font-mono text-sm">{{ member.id_users }}</td>
                  <td class="p-3 text-right">
                    <button 
                      @click="removeMember(member.portainer_user_id)" 
                      class="text-red-500 hover:text-red-700 text-sm hover:underline"
                    >
                      เตะออก
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>

            <div v-else class="h-48 flex flex-col items-center justify-center text-gray-400 border-2 border-dashed border-gray-100 rounded-lg">
              <div class="text-4xl mb-2">🍃</div>
              <p>ทีมนี้ยังไม่มีสมาชิก</p>
            </div>
          </div>
        </div>

        <!-- No Selection -->
        <div v-else class="h-full flex flex-col items-center justify-center text-gray-300">
          <div class="text-8xl mb-6 opacity-20">👈</div>
          <p class="text-xl font-medium text-gray-400">เลือกทีมจากฝั่งซ้าย</p>
          <p class="text-sm">เพื่อจัดการสมาชิก</p>
        </div>

      </div>
    </div>
  </div>
</template>