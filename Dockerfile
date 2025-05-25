FROM node:20-alpine AS builder
WORKDIR /app

# Dependencies for node-canvas
RUN apk update && apk add build-base g++ cairo-dev pango-dev giflib-dev cairo

COPY website-api/package*.json ./server/package.json
RUN cd ./server/ && yarn install --production=true

RUN npm i -g @vue/cli-service
COPY website-ui/package*.json ./ui/package.json
RUN cd ./ui/ && yarn install --production=true

COPY website-api/ ./server
COPY website-ui/ ./ui

# Build UI
RUN cd /app/ui/ && vue-cli-service build

FROM node:20-alpine AS prod
COPY --from=builder /app/server /app/server
COPY --from=builder /app/ui/dist /app/server/static
WORKDIR /app/server

ENV NODE_ENV=production
ENV STATIC_PATH=/app/server/static

EXPOSE 80
CMD ["node", "/app/server/index.js"]