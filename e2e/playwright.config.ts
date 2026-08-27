import { defineConfig, devices } from '@playwright/test'

const FRONTEND_PORT = 5173
const BACKEND_PORT = 3000

/**
 * The Rails backend runs with RAILS_ENV=test against the `backend_test`
 * database. The DB must be prepared and seeded before the run:
 *   bin/rails db:schema:load db:seed
 * (see .github/workflows/e2e.yml for the CI setup with a Postgres service).
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? [['github'], ['html', { open: 'never' }]] : 'list',

  use: {
    baseURL: `http://localhost:${FRONTEND_PORT}`,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],

  webServer: [
    {
      command: 'cd ../backend && RAILS_ENV=test bin/rails server -p 3000 -b 0.0.0.0',
      url: `http://localhost:${BACKEND_PORT}/event_types`,
      reuseExistingServer: !process.env.CI,
      timeout: 60_000,
      stdout: 'pipe',
      stderr: 'pipe',
    },
    {
      command: 'cd ../frontend && npm run build && npm run preview -- --port 5173 --strictPort',
      url: `http://localhost:${FRONTEND_PORT}`,
      reuseExistingServer: !process.env.CI,
      timeout: 60_000,
      stdout: 'pipe',
      stderr: 'pipe',
    },
  ],
})
