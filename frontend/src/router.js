import { createRouter, createWebHistory } from 'vue-router'
import EventTypesList from './views/EventTypesList.vue'
import BookEventType from './views/BookEventType.vue'
import OwnerDashboard from './views/OwnerDashboard.vue'

const routes = [
  { path: '/', name: 'event-types', component: EventTypesList },
  { path: '/event_types/:id/book', name: 'book', component: BookEventType, props: true },
  { path: '/owner', name: 'owner', component: OwnerDashboard },
]

export default createRouter({
  history: createWebHistory(),
  routes,
})
