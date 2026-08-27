import axios from 'axios'

const client = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api',
  headers: { 'Content-Type': 'application/json' },
})

export const listEventTypes = () =>
  client.get('/event_types').then((r) => r.data)

export const getEventType = (id) =>
  client.get(`/event_types/${id}`).then((r) => r.data)

export const listSlots = (eventTypeId) =>
  client.get(`/event_types/${eventTypeId}/slots`).then((r) => r.data)

export const createBooking = (payload) =>
  client.post('/bookings', payload).then((r) => r.data)

export const listOwnerBookings = () =>
  client.get('/owner/bookings').then((r) => r.data)

export const listOwnerEventTypes = () =>
  client.get('/owner/event_types').then((r) => r.data)

export const createOwnerEventType = (payload) =>
  client.post('/owner/event_types', payload).then((r) => r.data)

export default client
