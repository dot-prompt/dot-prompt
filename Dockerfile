# STEP 1: Build Assets
FROM node:22-alpine AS build_assets

WORKDIR /app

# Ensure correct path to server/apps/dot_prompt_server/assets
COPY server/apps/dot_prompt_server/assets/package*.json ./server/apps/dot_prompt_server/assets/
RUN cd server/apps/dot_prompt_server/assets && npm ci

COPY server/apps/dot_prompt_server/assets/ ./server/apps/dot_prompt_server/assets/
RUN cd server/apps/dot_prompt_server/assets && npm run build

# STEP 2: Build App
FROM elixir:1.18-slim AS build_app

RUN apt-get update && \
    apt-get install -y build-essential git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

# Fix: Copy from server/ correctly
COPY server/mix.exs server/mix.lock ./
COPY compilers/elixir/mix.exs ./compilers/elixir/
COPY server/apps/dot_prompt_server/mix.exs ./apps/dot_prompt_server/

RUN mix deps.get --only prod
RUN mix deps.compile

COPY server/config/ ./config/
COPY compilers/elixir/ ./compilers/elixir/
COPY server/apps/ ./apps/

# Copy built assets from STEP 1
COPY --from=build_assets /app/server/apps/dot_prompt_server/priv/static/ ./apps/dot_prompt_server/priv/static/

RUN mix do compile, release --overwrite

# STEP 3: Final Runtime Image - use bookworm-slim (stable) instead of sid-slim (unstable)
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y libssl3 ncurses-base ca-certificates locales inotify-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8

WORKDIR /app
RUN useradd -m elixir && chown -R elixir:elixir /app

USER elixir

COPY --from=build_app --chown=elixir:elixir /app/_build/prod/rel/dot_prompt_umbrella ./

ENV PORT=4000
EXPOSE 4000

ENTRYPOINT ["/app/bin/dot_prompt_umbrella"]
CMD ["start"]
