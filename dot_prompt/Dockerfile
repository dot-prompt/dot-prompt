FROM elixir:1.17-alpine
WORKDIR /app
COPY . .
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get
RUN mix compile
EXPOSE 4040 4041
CMD ["mix", "phx.server"]
