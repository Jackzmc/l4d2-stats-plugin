FROM node:lts-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
RUN apt-get update && apt-get install -y ttf-ancient-fonts
WORKDIR /app

FROM base AS builder
COPY . .
COPY .env* .

FROM builder AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM builder AS build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run build

FROM base
COPY --from=build /app/dist ./dist
COPY --from=prod-deps /app/node_modules ./node_modules

ENV HOST=0.0.0.0
ENV PORT=4321
ENV NODE_ENV=production

EXPOSE 4321
CMD ["node", "./dist/server/entry.mjs"]