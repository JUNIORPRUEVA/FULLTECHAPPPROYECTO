# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM node:20-bookworm-slim AS build
WORKDIR /app

# Prisma needs OpenSSL at build/runtime
RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Install deps first (better layer caching)
COPY package*.json ./
COPY prisma ./prisma
COPY sql ./sql
RUN npm ci

# Generate Prisma client (needed at runtime)
RUN npm run prisma:generate

# Build TypeScript
COPY tsconfig.json ./
COPY src ./src
RUN npm run build


# ---------- Runtime stage ----------
FROM node:20-bookworm-slim AS runtime
WORKDIR /app

# NOTE: EasyPanel is currently passing configuration as build args.
# We map those args into ENV so they are available at runtime.
# Prefer configuring these as runtime environment variables in EasyPanel instead.
ARG NODE_ENV=production
ARG PORT=3000
ARG JWT_SECRET
ARG JWT_EXPIRES_IN
ARG DATABASE_URL
ARG DEFAULT_EMPRESA_ID
ARG PUBLIC_BASE_URL
ARG UPLOADS_DIR
ARG MAX_UPLOAD_MB

# Evolution integration (aliases supported by app code)
ARG EVOLUTION_BASE_URL
ARG EVOLUTION_API_URL
ARG EVOLUTION_API_KEY
ARG EVOLUTION_INSTANCE
ARG EVOLUTION_INSTANCE_ID
ARG EVOLUTION_API_INSTANCE_NAME
ARG WEBHOOK_SECRET
ARG EVOLUTION_WEBHOOK_SECRET

ENV NODE_ENV=$NODE_ENV \
	PORT=$PORT \
	JWT_SECRET=$JWT_SECRET \
	JWT_EXPIRES_IN=$JWT_EXPIRES_IN \
	DATABASE_URL=$DATABASE_URL \
	DEFAULT_EMPRESA_ID=$DEFAULT_EMPRESA_ID \
	PUBLIC_BASE_URL=$PUBLIC_BASE_URL \
	UPLOADS_DIR=$UPLOADS_DIR \
	MAX_UPLOAD_MB=$MAX_UPLOAD_MB \
	EVOLUTION_BASE_URL=$EVOLUTION_BASE_URL \
	EVOLUTION_API_URL=$EVOLUTION_API_URL \
	EVOLUTION_API_KEY=$EVOLUTION_API_KEY \
	EVOLUTION_INSTANCE=$EVOLUTION_INSTANCE \
	EVOLUTION_INSTANCE_ID=$EVOLUTION_INSTANCE_ID \
	EVOLUTION_API_INSTANCE_NAME=$EVOLUTION_API_INSTANCE_NAME \
	WEBHOOK_SECRET=$WEBHOOK_SECRET \
	EVOLUTION_WEBHOOK_SECRET=$EVOLUTION_WEBHOOK_SECRET

# Prisma needs OpenSSL at runtime
RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Only production deps
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts

# Prisma client artifacts + schema
COPY --from=build /app/node_modules/.prisma /app/node_modules/.prisma
COPY --from=build /app/node_modules/@prisma /app/node_modules/@prisma
COPY --from=build /app/node_modules/@prisma/client /app/node_modules/@prisma/client
COPY --from=build /app/prisma /app/prisma
COPY --from=build /app/sql /app/sql

# App build output
COPY --from=build /app/dist /app/dist

# Default uploads dir inside container (mount a volume in EasyPanel)
RUN mkdir -p /app/uploads

EXPOSE 3000
CMD ["node", "dist/index.js"]
