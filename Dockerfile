FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY . .
RUN npm run build
RUN npm prune --omit=dev

FROM node:20-alpine

WORKDIR /app

RUN apk update && apk upgrade --no-cache

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma

RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx /opt/yarn-v1.22.22 /usr/local/lib/node_modules/corepack /usr/local/bin/corepack 2>/dev/null || true

EXPOSE 3001

CMD ["node", "dist/server.js"]
