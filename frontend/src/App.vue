<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="min-h-screen bg-gray-50 text-gray-900">
    <header class="border-b border-gray-200 bg-white">
      <div class="mx-auto flex max-w-4xl items-center justify-between px-4 py-4">
        <RouterLink to="/" class="text-lg font-semibold text-indigo-600">
          Call Booking
        </RouterLink>
        <nav class="flex gap-4 text-sm font-medium">
          <RouterLink to="/" class="hover:text-indigo-600">Event Types</RouterLink>
          <RouterLink to="/owner" class="hover:text-indigo-600">Owner</RouterLink>
        </nav>
      </div>
    </header>

    <main class="mx-auto max-w-4xl px-4 py-8">
      <RouterView />
    </main>
  </div>
</template>
