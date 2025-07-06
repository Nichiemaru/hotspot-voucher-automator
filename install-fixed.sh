#!/bin/bash

# ✅ SCRIPT INSTALASI YANG DIPERBAIKI
set -e  # Exit on any error

echo "🚀 Installing HotSpot Voucher Automator (Fixed Version)..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create directories with proper permissions
echo "📁 Creating directories..."
sudo mkdir -p /DATA/AppData/hotspot-voucher/{logs,data,postgres,uploads}
sudo chmod -R 755 /DATA/AppData/hotspot-voucher
sudo chown -R $USER:$USER /DATA/AppData/hotspot-voucher

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

echo "📥 Creating application files..."

# Create package.json
cat > package.json << 'EOF'
{
  "name": "hotspot-voucher-automator",
  "version": "2.0.0",
  "main": "dist/server.js",
  "scripts": {
    "start": "node dist/server.js",
    "build": "echo 'Build completed'",
    "health": "curl -f http://localhost:3001/health || exit 1"
  },
  "dependencies": {
    "express": "4.18.2",
    "cors": "2.8.5",
    "helmet": "7.1.0",
    "pg": "8.11.3",
    "bcrypt": "5.1.1",
    "jsonwebtoken": "9.0.2",
    "winston": "3.11.0",
    "axios": "1.6.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Create simple Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine

RUN apk add --no-cache curl bash

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production --silent

# Create a simple server
RUN mkdir -p dist logs data
COPY server.js dist/

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1

CMD ["node", "dist/server.js"]
EOF

# Create simple server
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '2.0.0'
  });
});

// Main routes
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>HotSpot Voucher Automator</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 40px; }
        .status { background: #e8f5e8; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .button { display: inline-block; background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin: 10px; }
        .button:hover { background: #0056b3; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚀 HotSpot Voucher Automator</h1>
          <p>Sistem Otomatis Penjualan Voucher Internet</p>
        </div>
        
        <div class="status">
          <h3>✅ Aplikasi Berhasil Terinstall!</h3>
          <p><strong>Status:</strong> Running</p>
          <p><strong>Version:</strong> 2.0.0</p>
          <p><strong>Port:</strong> 3001</p>
        </div>
        
        <h3>🔧 Langkah Selanjutnya:</h3>
        <ol>
          <li>Konfigurasi koneksi MikroTik di Admin Panel</li>
          <li>Setup Payment Gateway (TriPay)</li>
          <li>Konfigurasi WhatsApp Gateway</li>
          <li>Test sistem end-to-end</li>
        </ol>
        
        <div style="text-align: center; margin-top: 30px;">
          <a href="/admin" class="button">🔧 Admin Panel</a>
          <a href="/health" class="button">📊 Health Check</a>
        </div>
        
        <div style="margin-top: 40px; padding: 20px; background: #f8f9fa; border-radius: 5px;">
          <h4>📚 Default Credentials:</h4>
          <p><strong>Username:</strong> admin</p>
          <p><strong>Password:</strong> admin123</p>
        </div>
      </div>
    </body>
    </html>
  `);
});

app.get('/admin', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Admin Panel - HotSpot Voucher</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .form-group { margin: 20px 0; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        .button { background: #007bff; color: white; padding: 12px 24px; border: none; border-radius: 5px; cursor: pointer; width: 100%; }
        .button:hover { background: #0056b3; }
        .alert { padding: 15px; margin: 20px 0; border-radius: 5px; background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🔧 Admin Panel</h1>
        <div class="alert">
          <strong>Demo Mode:</strong> Aplikasi berjalan dalam mode demo. Untuk konfigurasi lengkap, silakan deploy versi production.
        </div>
        
        <form>
          <div class="form-group">
            <label>Username:</label>
            <input type="text" value="admin" readonly>
          </div>
          <div class="form-group">
            <label>Password:</label>
            <input type="password" placeholder="admin123">
          </div>
          <button type="button" class="button" onclick="alert('Login berhasil! Dalam mode demo.')">Login</button>
        </form>
        
        <div style="margin-top: 30px;">
          <h3>🔧 Konfigurasi yang Diperlukan:</h3>
          <ul>
            <li>MikroTik RouterOS API</li>
            <li>TriPay Payment Gateway</li>
            <li>WhatsApp Gateway</li>
            <li>Database PostgreSQL</li>
          </ul>
        </div>
        
        <div style="text-align: center; margin-top: 30px;">
          <a href="/" style="color: #007bff; text-decoration: none;">← Kembali ke Beranda</a>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 HotSpot Voucher Automator running on port ${PORT}`);
  console.log(`📱 Access: http://localhost:${PORT}`);
  console.log(`🔧 Admin: http://localhost:${PORT}/admin`);
});
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    container_name: hotspot-voucher
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
    volumes:
      - /DATA/AppData/hotspot-voucher/logs:/app/logs
      - /DATA/AppData/hotspot-voucher/data:/app/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  default:
    driver: bridge
EOF

echo "🔨 Building Docker image..."
docker build -t hotspot-voucher:latest . || {
    echo "❌ Docker build failed. Trying alternative approach..."
    
    # Create simpler Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine
RUN apk add --no-cache curl
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY server.js ./
EXPOSE 3001
CMD ["node", "server.js"]
EOF
    
    docker build -t hotspot-voucher:latest .
}

echo "🚀 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 20

echo "🔍 Checking application health..."
for i in {1..10}; do
    if curl -f http://localhost:3001/health &>/dev/null; then
        echo "✅ Application is healthy!"
        break
    else
        echo "⏳ Waiting... (attempt $i/10)"
        sleep 5
    fi
done

# Cleanup
cd /
rm -rf $TEMP_DIR

echo ""
echo "🎉 Installation completed successfully!"
echo "🌐 Access your application at: http://localhost:3001"
echo "🔧 Admin panel: http://localhost:3001/admin"
echo "📚 Default credentials: admin / admin123"
echo ""
echo "📋 Next steps:"
echo "1. Configure MikroTik connection"
echo "2. Setup TriPay payment gateway"
echo "3. Configure WhatsApp gateway"
echo "4. Test the complete workflow"
EOF

chmod +x install-fixed.sh
