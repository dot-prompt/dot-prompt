# STEP 1: Build Assets
FROM node:22-alpine AS build_assets
WORKDIR /app
COPY apps/dot_prompt_server/assets/package*.json ./apps/dot_prompt_server/assets/
RUN cd apps/dot_prompt_server/assets && npm install
COPY apps/dot_prompt_server/assets/ ./apps/dot_prompt_server/assets/
# Ensure all files are in the context
RUN npm run build --prefix apps/dot_prompt_server/assets

# STEP 2: Build App
FROM elixir:1.18-alpine AS build_app
RUN apk add --no-cache build-base git
WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force
ENV MIX_ENV=prod

# Copy mix files for dependency caching
COPY mix.exs mix.lock ./
COPY apps/dot_prompt/mix.exs ./apps/dot_prompt/
COPY apps/dot_prompt_server/mix.exs ./apps/dot_prompt_server/

RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source and config
COPY config/ ./config/
COPY apps/ ./apps/

# Copy assets from previous stage
COPY --from=build_assets /app/apps/dot_prompt_server/priv/static/ ./apps/dot_prompt_server/priv/static/

# Final compilation and release
RUN mix do compile, release --overwrite

# STEP 3: Final Runtime
FROM alpine:latest
RUN apk add --no-cache openssl ncurses-libs libstdc++ libgcc libcrypto3 inotify-tools && \
    addgroup -S elixir && adduser -S elixir -G elixir
WORKDIR /app
RUN chown -R elixir:elixir /app
USER elixir

# Copy the entire release
COPY --from=build_app --chown=elixir:elixir /app/_build/prod/rel/dot_prompt_umbrella ./

# Expose port
ENV PORT=4000
EXPOSE 4000

# Set entrypoint to the service bin
ENTRYPOINT ["/app/bin/dot_prompt_umbrella"]
CMD ["start"]
