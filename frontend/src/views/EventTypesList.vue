<script setup>
import { ref, onMounted } from 'vue'
import { listEventTypes } from '../api'

const eventTypes = ref([])
const loading = ref(true)
const error = ref(null)

onMounted(async () => {
  try {
    eventTypes.value = await listEventTypes()
  } catch (e) {
    error.value = 'Failed to load event types'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div>
    <h1 class="mb-6 text-2xl font-bold">Book a call</h1>

    <p v-if="loading" class="text-gray-500">Loading…</p>
    <p v-else-if="error" class="text-red-600">{{ error }}</p>

    <div v-else class="grid gap-4 sm:grid-cols-2">
      <div
        v-for="et in eventTypes"
        :key="et.id"
        class="rounded-lg border border-gray-200 bg-white p-5 shadow-sm"
      >
        <h2 class="text-lg font-semibold">{{ et.name }}</h2>
        <p class="mt-1 text-sm text-gray-600">{{ et.description }}</p>
        <p class="mt-2 text-sm font-medium text-gray-500">
          {{ et.duration_minutes }} min
        </p>
        <RouterLink
          :to="{ name: 'book', params: { id: et.id } }"
          class="mt-4 inline-block rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
        >
          Select
        </RouterLink>
      </div>
    </div>
  </div>
</template>
