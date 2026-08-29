# syntax=docker/dockerfile:1

ARG NODE_VERSION=20-alpine

#
# ---- deps: install full dependency tree (needed to compile TypeScript) ----
#
FROM node:${NODE_VERSION} AS deps
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000

#
# ---- build: compile TypeScript -> JavaScript ----
#
FROM node:${NODE_VERSION} AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json yarn.lock tsconfig.json ./
COPY src ./src
RUN yarn build

#
# ---- prod-deps: install only production dependencies ----
#
FROM node:${NODE_VERSION} AS prod-deps
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production --network-timeout 600000 \
    && yarn cache clean

#
# ---- runtime: minimal final image ----
#
FROM node:${NODE_VERSION} AS runtime
ENV NODE_ENV=production
WORKDIR /app

# Run as a non-root, unprivileged user (node:20-alpine ships a "node" user)
USER node

COPY --chown=node:node package.json ./
COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/index.js"]
