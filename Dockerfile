# ✅ MULTI-STAGE BUILD untuk optimasi ukuran
FROM node:18-alpine AS builder

WORKDIR /app

# ✅ Copy package files terlebih dahulu untuk caching
COPY package*.json ./
COPY tsconfig*.json ./
COPY vite.config.ts ./
COPY tailwind.config.ts ./
COPY postcss.config.js ./

# ✅ Install dependencies dengan cache mounting
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production --silent

# ✅ Copy source code
COPY src/ ./src/
COPY public/ ./public/
COPY index.html ./
COPY components.json ./

# ✅ Build aplikasi
RUN npm run build

# ✅ PRODUCTION STAGE
FROM node:18-alpine AS production

# ✅ Install curl untuk health check
RUN apk add --no-cache curl

WORKDIR /app

# ✅ Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# ✅ Create necessary directories
RUN mkdir -p logs data uploads

# ✅ Create non-root user untuk security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 && \
    chown -R nextjs:nodejs /app

USER nextjs

# ✅ Expose port
EXPOSE 3001

# ✅ Health check yang robust
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1

# ✅ Start command dengan proper signal handling
CMD ["node", "dist/server.js"]
