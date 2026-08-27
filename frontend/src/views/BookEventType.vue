<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getEventType, listSlots, createBooking } from '../api'

const props = defineProps({ id: { type: [String, Number], required: true } })
const router = useRouter()

const eventType = ref(null)
const slots = ref([])
const selectedSlot = ref(null)
const guestName = ref('')
const guestEmail = ref('')
const loading = ref(true)
const submitting = ref(false)
const error = ref(null)
const confirmed = ref(null)

const canSubmit = computed(
  () => selectedSlot.value && guestName.value && guestEmail.value,
)

function formatSlot(iso) {
  return new Date(iso).toLocaleString()
}

async function loadSlots() {
  slots.value = await listSlots(props.id)
}

onMounted(async () => {
  try {
    eventType.value = await getEventType(props.id)
    await loadSlots()
  } catch (e) {
    error.value = 'Failed to load event type'
  } finally {
    loading.value = false
  }
})

async function submit() {
  error.value = null
  submitting.value = true
  try {
    confirmed.value = await createBooking({
      event_type_id: Number(props.id),
      start_at: selectedSlot.value,
      guest_name: guestName.value,
      guest_email: guestEmail.value,
    })
  } catch (e) {
    if (e.response?.status === 409) {
      error.value = 'This slot was just taken. Please pick another.'
      selectedSlot.value = null
      await loadSlots()
    } else {
      error.value = e.response?.data?.message || 'Booking failed'
    }
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div>
    <RouterLink to="/" class="text-sm text-indigo-600 hover:underline">
      &larr; Back
    </RouterLink>

    <p v-if="loading" class="mt-4 text-gray-500">Loading…</p>

    <div v-else-if="confirmed" class="mt-6 rounded-lg border border-green-200 bg-green-50 p-6">
      <h2 class="text-lg font-semibold text-green-800">Booking confirmed!</h2>
      <p class="mt-2 text-sm text-green-700">
        {{ confirmed.event_type_name }} with {{ confirmed.guest_name }}
      </p>
      <p class="text-sm text-green-700">{{ formatSlot(confirmed.start_at) }}</p>
    </div>

    <div v-else-if="eventType" class="mt-4">
      <h1 class="text-2xl font-bold">{{ eventType.name }}</h1>
      <p class="mt-1 text-gray-600">{{ eventType.description }}</p>
      <p class="mt-1 text-sm text-gray-500">{{ eventType.duration_minutes }} min</p>

      <p v-if="error" class="mt-4 rounded-md bg-red-50 p-3 text-sm text-red-700">
        {{ error }}
      </p>

      <h3 class="mt-6 mb-2 font-semibold">Pick a time</h3>
      <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
        <button
          v-for="slot in slots"
          :key="slot.start_at"
          type="button"
          :data-start-at="slot.start_at"
          @click="selectedSlot = slot.start_at"
          :class="[
            'rounded-md border px-3 py-2 text-sm',
            selectedSlot === slot.start_at
              ? 'border-indigo-600 bg-indigo-600 text-white'
              : 'border-gray-300 bg-white hover:border-indigo-400',
          ]"
        >
          {{ formatSlot(slot.start_at) }}
        </button>
      </div>
      <p v-if="slots.length === 0" class="text-sm text-gray-500">
        No slots available.
      </p>

      <form class="mt-6 space-y-4" @submit.prevent="submit">
        <div>
          <label for="guest-name" class="block text-sm font-medium">Name</label>
          <input
            id="guest-name"
            v-model="guestName"
            type="text"
            class="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label for="guest-email" class="block text-sm font-medium">Email</label>
          <input
            id="guest-email"
            v-model="guestEmail"
            type="email"
            class="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
          />
        </div>
        <button
          type="submit"
          :disabled="!canSubmit || submitting"
          class="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:opacity-50"
        >
          {{ submitting ? 'Booking…' : 'Confirm booking' }}
        </button>
      </form>
    </div>
  </div>
</template>
