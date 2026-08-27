### Hexlet tests and linter status:
[![Actions Status](https://github.com/kkrasilov/ai-for-developers-project-386/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/kkrasilov/ai-for-developers-project-386/actions)

# Call Booking

A small call-booking service. Guests browse available event types (e.g. "Intro
Call", "Consultation"), pick a free time slot and book it. The owner has a
simple dashboard to see upcoming bookings and create new event types.

## Architecture

The project is split into independent parts living in this monorepo:

| Directory  | Purpose                                                              |
| ---------- | --------------------------------------------------------------------- |
| `backend/` | Ruby on Rails 8 JSON API (event types, slots, bookings)               |
| `frontend/`| Vue 3 + Vite single-page app (guest and owner UI), talks to the API   |
| `api/`     | TypeSpec source used to generate `openapi.yaml`                       |
| `e2e/`     | Playwright end-to-end tests covering the booking flow                 |

For local development the frontend and backend run as two separate
processes: Vite's dev server proxies `/api/*` requests to the Rails server on
`localhost:3000` (see `frontend/vite.config.js`).

For deployment, both parts are packaged into a **single Docker image** (see
the root `Dockerfile`): the frontend is built and its static files are
copied into the Rails `public/` directory, so one Rails/Puma process serves
both the API and the UI on one port. See [`AGENTS.md`](./AGENTS.md) for
details on how requests are routed.

## Tech stack

- **Backend**: Ruby 3.2.2, Rails 8 (API-only), PostgreSQL, Solid Queue / Solid
  Cache / Solid Cable, Puma
- **Frontend**: Vue 3, Vue Router, Vite, Tailwind CSS, Axios
- **API contract**: TypeSpec → OpenAPI (`openapi.yaml`)
- **E2E tests**: Playwright
- **CI**: GitHub Actions (e2e tests, commitlint, release-please, Hexlet checks)
- **Deployment**: Docker, [Render](https://render.com) (`render.yaml` blueprint)

## Getting started

### Prerequisites

- Ruby 3.2.2 (see `backend/.ruby-version`)
- Node.js 20 (see `.tool-versions`)
- PostgreSQL

### Backend

```bash
cd backend
bundle install
bin/rails db:prepare
bin/rails server
```

The API is available at `http://localhost:3000`.

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The app is available at `http://localhost:5173`, with `/api/*` requests
proxied to the backend.

### End-to-end tests

```bash
cd e2e
npm install
npx playwright install --with-deps chromium
npm test
```

This spins up the backend (RAILS_ENV=test) and the frontend build/preview
server automatically (see `e2e/playwright.config.ts`).

## Running with Docker

Build and run the whole app (frontend + backend) as a single container:

```bash
docker build -t call-booking .
docker run -p 3000:3000 \
  -e PORT=3000 \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e DATABASE_HOST=<postgres-host> \
  -e DATABASE_USER=<postgres-user> \
  -e DATABASE_PASSWORD=<postgres-password> \
  -e BACKEND_DATABASE_PASSWORD=<postgres-password> \
  call-booking
```

The app listens on the port from the `PORT` environment variable and is
available at `http://localhost:3000`.

## Deployment (Render)

The repository includes a `render.yaml` Blueprint that provisions:

- a Postgres database
- a web service built from the root `Dockerfile`, listening on the `PORT`
  environment variable Render provides automatically

To deploy: in the Render Dashboard choose **New > Blueprint**, point it at
this repository, and apply. See [`AGENTS.md`](./AGENTS.md) for more details
about the request routing and required environment variables.
