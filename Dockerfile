FROM node:20-alpine AS builder
WORKDIR /app

# Dependencies for node-canvas
RUN apk update && apk add build-base g++ cairo-dev pango-dev giflib-dev cairo

COPY website-api/package*.json ./server/package.json
COPY website-ui/package*.json ./ui/package.json

RUN npm i -g @vue/cli-service
RUN cd ./server/ && yarn install --production=true
RUN cd ./ui/ && yarn install --production=true

COPY website-api/ ./server
COPY website-ui/ ./ui

# Build UI
RUN cd /app/ui/ && yarn build

# FROM node:20-alpine AS prod
# COPY --from=builder /app /app
WORKDIR /app/server

ENV NODE_ENV=production
ENV STATIC_PATH=/app/ui/dist

EXPOSE 80
CMD ["node", "/app/server/index.js"]