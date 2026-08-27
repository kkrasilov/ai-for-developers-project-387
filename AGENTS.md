# AGENTS.md

This file gives AI coding agents (and humans) the context needed to work on
this repository safely and consistently.

## What this project is

**Call Booking** — a booking service where guests pick an event type (e.g.
"Intro Call", "Consultation", "Deep Dive"), see available time slots, and
book one. The owner has a minimal dashboard to view upcoming bookings and
create new event types.

## Repository layout

```
backend/   Ruby on Rails 8 JSON API (API-only, no server-rendered views)
frontend/  Vue 3 + Vite SPA (guest booking UI + owner dashboard)
api/       TypeSpec source (main.tsp) -> generates openapi.yaml at the repo root
e2e/       Playwright end-to-end tests against the running app
```

There is **no root package manager / monorepo tool** (no npm workspaces,
turborepo, pnpm, etc). Each directory (`backend`, `frontend`, `api`, `e2e`)
is an independent project with its own dependency lockfile.

## Backend (`backend/`)

- Ruby 3.2.2, Rails 8, `config.api_only = true`.
- Database: PostgreSQL. In production, Rails 8's multi-database defaults are
  used: `backend_production` (primary), plus separate physical databases for
  Solid Cache, Solid Queue and Solid Cable (see `config/database.yml`). All
  four are created automatically on boot via `bin/rails db:prepare`, invoked
  from `bin/docker-entrypoint`.
- Server: Puma, listening on `ENV.fetch("PORT", 3000)` (`config/puma.rb`).
  **Always read the port from `PORT`; never hardcode it.**
- Key models: `EventType` (has `available_slots`, generates free slots for
  the next few days within working hours) and `Booking` (belongs to
  `EventType`, validates the slot isn't already taken).
- Routes (`config/routes.rb`):
  - `GET /event_types`, `GET /event_types/:id`
  - `GET /event_types/:id/slots`
  - `POST /bookings`
  - `GET /owner/bookings`, `GET /owner/event_types`, `POST /owner/event_types`
  - `GET /up` — health check (used by Render's health check and CI)
  - `get "*path" => "spa#index"` (constrained to HTML requests) plus
    `root => "spa#index"` — serves the built frontend for any other GET
    request. This lets a single Rails process serve both the API and the
    UI. Do not remove this without also updating the deployment story.
- CORS (`rack-cors`, `config/initializers/cors.rb`) is configured for a
  separate frontend origin via `FRONTEND_ORIGIN` (default
  `http://localhost:5173`). This is only relevant when frontend and backend
  are deployed separately (e.g. local dev); when served from the same
  origin (the production Docker image) CORS is not exercised.
- `config/environments/production.rb` sets `assume_ssl = true` and
  `force_ssl = true`, assuming a TLS-terminating reverse proxy in front of
  the app (true for Render).
- No `config/master.key` is committed (correctly gitignored). Production
  reads `ENV["SECRET_KEY_BASE"]` directly, so **no Rails credentials/master
  key are required to run in production** — just set `SECRET_KEY_BASE`.

## Frontend (`frontend/`)

- Vue 3 + Vue Router (history mode) + Vite + Tailwind CSS.
- API calls go through `src/api.js`, an Axios instance with
  `baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api'`.
  - In dev, `VITE_API_BASE_URL` is unset, so it defaults to `/api`, and
    Vite's dev server proxies `/api/*` to `http://localhost:3000` while
    stripping the `/api` prefix (`vite.config.js`).
  - In the production Docker build, `VITE_API_BASE_URL` is set to an empty
    string at build time, because the built SPA is served by the same Rails
    process as the API (same origin, no `/api` prefix on Rails routes).
- Build output goes to `frontend/dist/`.

## API contract (`api/`)

- `api/main.tsp` is the source of truth for the API shape (TypeSpec). It
  compiles to `openapi.yaml` at the repo root. If you change backend
  request/response shapes, update `main.tsp` and regenerate the OpenAPI spec
  (see `api/package.json` for the compile command) instead of hand-editing
  `openapi.yaml`.

## End-to-end tests (`e2e/`)

- Playwright, TypeScript. `e2e/playwright.config.ts` starts both the backend
  (`RAILS_ENV=test`, port 3000) and the frontend (`npm run build && npm run
  preview`, port 5173) as separate `webServer` processes and runs tests
  against `http://localhost:5173`.
- Before running locally, prepare the Rails test database:
  `cd backend && bin/rails db:schema:load db:seed`.

## Docker / deployment

- **Root `Dockerfile`** is the single source of truth for how the app is
  packaged for deployment. It's a multi-stage build:
  1. `frontend-build` stage: Node 20, `npm ci && npm run build` with
     `VITE_API_BASE_URL=""`.
  2. `build` stage: Ruby 3.2.2, `bundle install`, copies backend code, then
     copies the built frontend into `backend/public/`.
  3. Final stage: copies gems + app from the build stage, runs as a
     non-root user, and starts with `bin/docker-entrypoint` →
     `./bin/rails server`.
- The app **must** listen on the port from the `PORT` environment variable
  (already the case via `config/puma.rb`). Don't hardcode ports in the
  Dockerfile or app code.
- `bin/docker-entrypoint` runs `bin/rails db:prepare` automatically before
  starting the server, so the container is self-sufficient given a reachable
  Postgres instance and correct `DATABASE_*` env vars.
- **`render.yaml`** is a Render Blueprint that provisions a Postgres
  database and a Docker-based web service built from the root `Dockerfile`.
  Required env vars for a manual (non-blueprint) deploy:
  - `SECRET_KEY_BASE` (random secret, no master key needed)
  - `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`
  - `BACKEND_DATABASE_PASSWORD` (used specifically by the `production`
    block in `config/database.yml`)
  - `PORT` is provided by Render automatically; don't set it manually
    unless testing locally.
- There is also a separate `backend/Dockerfile` (Rails-only, generated by
  `rails new`, used by Kamal — see `backend/config/deploy.yml` and
  `backend/.kamal/`). **The root `Dockerfile` is the one used for the actual
  Render deployment**; don't confuse the two.

## Conventions for changes

- Commit messages follow Conventional Commits (enforced by commitlint,
  `commitlint.config.mjs`, checked in CI on PRs).
- `release-please` manages versioning/changelog based on commit messages —
  don't hand-edit `.release-please-manifest.json` or version numbers.
- `.github/workflows/hexlet-check.yml` is managed by the Hexlet platform —
  do not edit, rename, or delete it.
- If you change how the frontend calls the API or how the backend routes
  requests, update both `frontend/src/api.js`/`vite.config.js` **and**
  `backend/config/routes.rb`/CORS config together, and keep the root
  `Dockerfile`'s same-origin assumption (`VITE_API_BASE_URL=""`) working.
