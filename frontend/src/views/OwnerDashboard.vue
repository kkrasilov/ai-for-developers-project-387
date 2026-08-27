<script setup>
import { ref, onMounted } from 'vue'
import {
  listOwnerBookings,
  listOwnerEventTypes,
  createOwnerEventType,
} from '../api'

const bookings = ref([])
const eventTypes = ref([])
const error = ref(null)

const form = ref({ name: '', description: '', duration_minutes: 30 })
const submitting = ref(false)

function formatSlot(iso) {
  return new Date(iso).toLocaleString()
}

async function loadAll() {
  ;[bookings.value, eventTypes.value] = await Promise.all([
    listOwnerBookings(),
    listOwnerEventTypes(),
  ])
}

onMounted(async () => {
  try {
    await loadAll()
  } catch (e) {
    error.value = 'Failed to load owner data'
  }
})

async function addEventType() {
  error.value = null
  submitting.value = true
  try {
    await createOwnerEventType({
      name: form.value.name,
      description: form.value.description,
      duration_minutes: Number(form.value.duration_minutes),
    })
    form.value = { name: '', description: '', duration_minutes: 30 }
    await loadAll()
  } catch (e) {
    error.value = e.response?.data?.message || 'Failed to create event type'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="space-y-10">
    <h1 class="text-2xl font-bold">Owner dashboard</h1>

    <p v-if="error" class="rounded-md bg-red-50 p-3 text-sm text-red-700">
      {{ error }}
    </p>

    <section>
      <h2 class="mb-3 text-lg font-semibold">Upcoming bookings</h2>
      <div v-if="bookings.length" class="overflow-hidden rounded-lg border border-gray-200 bg-white">
        <table class="w-full text-left text-sm">
          <thead class="bg-gray-50 text-gray-500">
            <tr>
              <th class="px-4 py-2">Event</th>
              <th class="px-4 py-2">Guest</th>
              <th class="px-4 py-2">Email</th>
              <th class="px-4 py-2">When</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="b in bookings" :key="b.id" class="border-t border-gray-100">
              <td class="px-4 py-2">{{ b.event_type_name }}</td>
              <td class="px-4 py-2">{{ b.guest_name }}</td>
              <td class="px-4 py-2">{{ b.guest_email }}</td>
              <td class="px-4 py-2">{{ formatSlot(b.start_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-else class="text-sm text-gray-500">No upcoming bookings.</p>
    </section>

    <section>
      <h2 class="mb-3 text-lg font-semibold">Event types</h2>
      <ul class="mb-6 space-y-2">
        <li
          v-for="et in eventTypes"
          :key="et.id"
          class="rounded-md border border-gray-200 bg-white px-4 py-3 text-sm"
        >
          <span class="font-medium">{{ et.name }}</span>
          <span class="text-gray-500"> — {{ et.duration_minutes }} min</span>
        </li>
      </ul>

      <form class="max-w-md space-y-4" @submit.prevent="addEventType">
        <h3 class="font-semibold">Create event type</h3>
        <div>
          <label class="block text-sm font-medium">Name</label>
          <input
            v-model="form.name"
            type="text"
            required
            class="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label class="block text-sm font-medium">Description</label>
          <textarea
            v-model="form.description"
            required
            class="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label class="block text-sm font-medium">Duration (minutes)</label>
          <input
            v-model="form.duration_minutes"
            type="number"
            min="1"
            required
            class="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
          />
        </div>
        <button
          type="submit"
          :disabled="submitting"
          class="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:opacity-50"
        >
          {{ submitting ? 'Saving…' : 'Create' }}
        </button>
      </form>
    </section>
  </div>
</template>
