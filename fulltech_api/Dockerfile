# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM node:20-alpine AS build
WORKDIR /app

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
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

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
