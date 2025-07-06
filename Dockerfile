FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache \
    curl \
    wget \
    bash \
    tzdata \
    && rm -rf /var/cache/apk/*

# Set timezone
ENV TZ=Asia/Jakarta

WORKDIR /app

# Create package.json
RUN echo '{ \
  "name": "hotspot-voucher-fresh", \
  "version": "2.1.0", \
  "description": "Fresh Install HotSpot Voucher System for CasaOS", \
  "main": "server.js", \
  "scripts": { \
    "start": "node server.js", \
    "health": "wget --spider -q http://localhost:3001/health || exit 1" \
  }, \
  "dependencies": { \
    "express": "4.18.2", \
    "cors": "2.8.5", \
    "helmet": "7.1.0", \
    "compression": "1.7.4" \
  }, \
  "engines": { \
    "node": ">=18.0.0" \
  } \
}' > package.json

# Install dependencies
RUN npm install --production --silent --no-audit --no-fund

# Copy server file
COPY server.js .

# Create directories and user
RUN mkdir -p logs data config uploads && \
    addgroup -g 1001 -S nodejs && \
    adduser -S hotspot -u 1001 -G nodejs && \
    chown -R hotspot:nodejs /app

USER hotspot

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

CMD ["node", "server.js"]
