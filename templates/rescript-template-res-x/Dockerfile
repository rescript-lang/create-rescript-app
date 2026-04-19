FROM oven/bun:1 AS build

ENV HUSKY=0
ENV NODE_ENV=production

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .
RUN bun run build:sfe

FROM debian:bookworm-slim

RUN apt-get update && \
  apt-get install -y --no-install-recommends ca-certificates tzdata && \
  rm -rf /var/lib/apt/lists/* && \
  groupadd --system app && \
  useradd --system --gid app --home-dir /app --create-home app

ENV NODE_ENV=production
ENV PORT=5555
ENV TZ=Europe/Stockholm

WORKDIR /app

COPY --from=build --chown=app:app /app/build/resx-template ./resx-template

USER app

EXPOSE 5555

CMD ["./resx-template"]
