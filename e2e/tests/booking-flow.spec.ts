import { test, expect } from '@playwright/test'

test.describe('Guest booking flow', () => {
  test('guest can browse event types, pick a slot and confirm a booking', async ({ page }) => {
    // Use a unique guest email per run so re-runs against the same DB
    // don't collide with the unique (event_type_id, start_at) constraint
    // from a previous booking of the exact same slot.
    const guestEmail = `guest+${Date.now()}@example.com`

    await page.goto('/')
    await expect(page.getByRole('heading', { name: 'Book a call' })).toBeVisible()

    const firstCard = page.locator('div.grid > div').first()
    const eventTypeName = await firstCard.getByRole('heading').innerText()
    await firstCard.getByRole('link', { name: 'Select' }).click()

    await expect(page.getByRole('heading', { name: eventTypeName })).toBeVisible()

    const slotButtons = page.locator('button', { hasText: /\d/ })
    await expect(slotButtons.first()).toBeVisible()
    await slotButtons.first().click()

    await page.getByLabel('Name').fill('Ada Lovelace')
    await page.getByLabel('Email').fill(guestEmail)

    await page.getByRole('button', { name: 'Confirm booking' }).click()

    await expect(page.getByRole('heading', { name: 'Booking confirmed!' })).toBeVisible()
    await expect(page.getByText(`${eventTypeName} with Ada Lovelace`)).toBeVisible()
  })

  test('booking a slot that was just taken by someone else shows a conflict', async ({ page, request }) => {
    await page.goto('/event_types/1/book')
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible()

    const slotButtons = page.locator('button', { hasText: /\d/ })
    await expect(slotButtons.first()).toBeVisible()

    const startAt = await slotButtons.first().getAttribute('data-start-at')
    await slotButtons.first().click()
    await page.getByLabel('Name').fill('Second Guest')
    await page.getByLabel('Email').fill(`second+${Date.now()}@example.com`)

    // Simulate another guest grabbing the exact same slot right before submit.
    const raceResponse = await request.post('/api/bookings', {
      data: {
        event_type_id: 1,
        start_at: startAt,
        guest_name: 'First Guest',
        guest_email: `first+${Date.now()}@example.com`,
      },
    })
    expect(raceResponse.ok()).toBeTruthy()

    await page.getByRole('button', { name: 'Confirm booking' }).click()

    await expect(page.getByText('This slot was just taken. Please pick another.')).toBeVisible()
  })
})
