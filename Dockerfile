# ✅ DOCKERFILE YANG DIPERBAIKI - MULTI-STAGE BUILD
FROM node:18-alpine AS base

# Install dependencies yang diperlukan
RUN apk add --no-cache \
    curl \
    bash \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# ✅ STAGE 1: Dependencies
FROM base AS deps
COPY package*.json ./
RUN npm ci --only=production --silent --no-audit --no-fund

# ✅ STAGE 2: Build
FROM base AS builder
COPY package*.json ./
RUN npm ci --silent --no-audit --no-fund

# Copy source files
COPY . .
RUN npm run build

# ✅ STAGE 3: Production
FROM node:18-alpine AS runner

# Install runtime dependencies
RUN apk add --no-cache curl bash

WORKDIR /app

# Create user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Create directories
RUN mkdir -p logs data uploads && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1

CMD ["node", "dist/server.js"]
