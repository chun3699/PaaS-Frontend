<script setup lang="ts">
const { logout } = useAuth()
</script>

<template>
  <div class="flex h-screen bg-gray-100 font-sans">
    <!-- Sidebar -->
    <aside class="w-64 bg-slate-900 text-white flex flex-col shadow-xl">
      <div class="p-6 text-xl font-bold border-b border-slate-700 flex items-center gap-2">
        🛠️ <span class="text-blue-400">PaaS</span> Admin
      </div>

      <nav class="flex-1 p-4 space-y-2">
        <div class="text-xs text-gray-500 uppercase font-semibold mb-2 ml-2">Main Menu</div>

        <NuxtLink to="/dashboard/environments" class="nav-item">
          🏫 Environments
        </NuxtLink>

        <NuxtLink to="/dashboard/teams" class="nav-item">
          🤝 Manage Teams
        </NuxtLink>

        <NuxtLink to="/dashboard/users" class="nav-item">
          👥 Users & Ports
        </NuxtLink>

        <NuxtLink to="/dashboard/projects" class="nav-item">
          🔌 Port Reservation
        </NuxtLink>
      </nav>

      <div class="p-4 bg-slate-800">
        <button @click="logout"
          class="w-full bg-red-600 hover:bg-red-700 text-white py-2 rounded transition flex items-center justify-center gap-2">
          🚪 Logout
        </button>
      </div>
    </aside>

    <!-- Content Area -->
    <main class="flex-1 overflow-auto p-8">
      <slot />
    </main>
  </div>
</template>

<style scoped>
.nav-item {
  @apply flex items-center px-4 py-3 rounded-lg transition-colors hover:bg-slate-700 text-gray-300 hover:text-white;
}

.router-link-active {
  @apply bg-blue-600 text-white shadow-lg;
}
</style>