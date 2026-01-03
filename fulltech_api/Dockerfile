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
ENV NODE_ENV=production

# Prisma needs OpenSSL at runtime
RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Only production deps
COPY package*.json ./
RUN npm ci --omit=dev

# Prisma client artifacts + schema
COPY --from=build /app/node_modules/.prisma /app/node_modules/.prisma
COPY --from=build /app/node_modules/@prisma /app/node_modules/@prisma
COPY --from=build /app/prisma /app/prisma

# App build output
COPY --from=build /app/dist /app/dist

# Default uploads dir inside container (mount a volume in EasyPanel)
RUN mkdir -p /app/uploads

EXPOSE 3000
CMD ["node", "dist/index.js"]
