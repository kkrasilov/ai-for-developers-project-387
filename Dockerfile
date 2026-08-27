# syntax=docker/dockerfile:1
# check=error=true
#
# Single-container build: builds the Vue/Vite frontend and packages it as
# static assets served by the Rails API backend. The Rails server listens
# on the port provided via the PORT environment variable (see
# backend/config/puma.rb), so the same image works locally and on Render.
#
# Build:  docker build -t app .
# Run:    docker run -p 3000:3000 -e PORT=3000 -e RAILS_MASTER_KEY=... -e SECRET_KEY_BASE=... app

ARG RUBY_VERSION=3.2.2
ARG NODE_VERSION=20

#########################
# 1. Build the frontend #
#########################
FROM node:${NODE_VERSION}-alpine AS frontend-build

WORKDIR /frontend

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
# Same-origin deployment: the API is served by the same host/port, so no
# "/api" proxy prefix is needed in production.
ENV VITE_API_BASE_URL=""
RUN npm run build

########################
# 2. Backend build base #
########################
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

##########################
# 3. Backend build stage #
##########################
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY backend/vendor/* ./vendor/
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY backend/ .

# Bring the compiled frontend into Rails' public/ directory so it can be
# served as static assets alongside the JSON API.
COPY --from=frontend-build /frontend/dist/ ./public/

RUN bundle exec bootsnap precompile --gemfile && \
    bundle exec bootsnap precompile app/ lib/

#########################
# 4. Final runtime image #
#########################
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp public
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# The app listens on the port from the PORT env var (defaults to 3000, see
# backend/config/puma.rb). Render sets PORT automatically at deploy time.
ENV PORT=3000
EXPOSE 3000
CMD ["./bin/rails", "server"]
