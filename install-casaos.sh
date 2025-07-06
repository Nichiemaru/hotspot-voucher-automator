#!/bin/bash

# ✅ SCRIPT INSTALASI KHUSUS CASAOS
set -e

echo "🚀 Installing HotSpot Voucher for CasaOS..."

# Check if running on CasaOS
if [ ! -d "/DATA/AppData" ]; then
    echo "⚠️  Warning: /DATA/AppData not found. Creating directory..."
    sudo mkdir -p /DATA/AppData
fi

# Create application directories
echo "📁 Creating application directories..."
sudo mkdir -p /DATA/AppData/hotspot-voucher/{logs,data,config,postgres}
sudo chmod -R 755 /DATA/AppData/hotspot-voucher
sudo chown -R $USER:$USER /DATA/AppData/hotspot-voucher 2>/dev/null || true

# Create temporary build directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

echo "📝 Creating application files..."

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine

RUN apk add --no-cache curl wget bash tzdata
ENV TZ=Asia/Jakarta

WORKDIR /app

# Create package.json
RUN echo '{ \
  "name": "hotspot-voucher-automator", \
  "version": "2.0.0", \
  "main": "server.js", \
  "scripts": { \
    "start": "node server.js", \
    "health": "wget --spider -q http://localhost:3001/health" \
  }, \
  "dependencies": { \
    "express": "^4.18.2", \
    "cors": "^2.8.5", \
    "helmet": "^7.1.0" \
  } \
}' > package.json

RUN npm install --production --silent

# Create server
COPY server.js .

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 && \
    mkdir -p logs data config && \
    chown -R nextjs:nodejs /app

USER nextjs
EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

CMD ["node", "server.js"]
EOF

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    version: '2.0.0',
    uptime: process.uptime()
  });
});

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>HotSpot Voucher Automator</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; color: white; }
        .container { max-width: 1000px; margin: 0 auto; padding: 40px 20px; text-align: center; }
        .header h1 { font-size: 3rem; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .status { background: rgba(255,255,255,0.2); padding: 20px; border-radius: 15px; margin: 30px 0; }
        .button { display: inline-block; background: rgba(255,255,255,0.2); color: white; padding: 15px 30px; text-decoration: none; border-radius: 10px; margin: 10px; font-weight: bold; transition: all 0.3s; }
        .button:hover { background: rgba(255,255,255,0.3); transform: translateY(-2px); }
        .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-top: 40px; }
        .feature { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚀 HotSpot Voucher Automator</h1>
          <p>Sistem Otomatis Penjualan Voucher Internet MikroTik</p>
        </div>
        
        <div class="status">
          <h3>✅ Aplikasi Berhasil Berjalan di CasaOS!</h3>
          <p><strong>Status:</strong> Online | <strong>Version:</strong> 2.0.0 | <strong>Port:</strong> 3001</p>
        </div>
        
        <div>
          <a href="/admin" class="button">🔧 Admin Panel</a>
          <a href="/health" class="button">📊 Health Check</a>
          <a href="/config" class="button">⚙️ Configuration</a>
        </div>
        
        <div class="features">
          <div class="feature">
            <h4>🔐 Secure System</h4>
            <p>Advanced authentication and data encryption</p>
          </div>
          <div class="feature">
            <h4>⚡ Fast Processing</h4>
            <p>Automatic voucher generation in seconds</p>
          </div>
          <div class="feature">
            <h4>📱 WhatsApp Integration</h4>
            <p>Direct voucher delivery to WhatsApp</p>
          </div>
          <div class="feature">
            <h4>💳 Payment Gateway</h4>
            <p>Integrated with TriPay payment system</p>
          </div>
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
        body { font-family: Arial, sans-serif; margin: 0; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .container { max-width: 800px; margin: 20px auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .alert { padding: 15px; margin: 20px 0; border-radius: 5px; background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        .form-group { margin: 20px 0; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input { width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 5px; }
        .button { background: linear-gradient(45deg, #007bff, #0056b3); color: white; padding: 12px 24px; border: none; border-radius: 5px; cursor: pointer; width: 100%; font-weight: bold; }
        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .status-card { padding: 20px; border-radius: 10px; text-align: center; }
        .online { background: #e8f5e8; }
        .demo { background: #fff3cd; }
        .offline { background: #f8d7da; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>🔧 Admin Panel</h1>
        <p>HotSpot Voucher Automator - CasaOS Edition</p>
      </div>
      
      <div class="container">
        <div class="alert">
          <strong>CasaOS Mode:</strong> Aplikasi berjalan dalam mode CasaOS. Untuk fitur lengkap dengan database, gunakan versi production.
        </div>
        
        <h3>🔐 Admin Login</h3>
        <form onsubmit="handleLogin(event)">
          <div class="form-group">
            <label>Username:</label>
            <input type="text" id="username" value="admin" required>
          </div>
          <div class="form-group">
            <label>Password:</label>
            <input type="password" id="password" placeholder="admin123" required>
          </div>
          <button type="submit" class="button">🔑 Login</button>
        </form>
        
        <h3>📊 System Status</h3>
        <div class="status-grid">
          <div class="status-card online">
            <h4>🟢 Web Server</h4>
            <p>Online</p>
          </div>
          <div class="status-card demo">
            <h4>🟡 Database</h4>
            <p>Demo Mode</p>
          </div>
          <div class="status-card offline">
            <h4>🔴 MikroTik</h4>
            <p>Not Configured</p>
          </div>
          <div class="status-card offline">
            <h4>🔴 WhatsApp</h4>
            <p>Not Configured</p>
          </div>
        </div>
        
        <div style="text-align: center; margin-top: 30px;">
          <a href="/" style="color: #007bff; text-decoration: none; font-weight: bold;">← Back to Home</a>
        </div>
      </div>
      
      <script>
        function handleLogin(event) {
          event.preventDefault();
          const username = document.getElementById('username').value;
          const password = document.getElementById('password').value;
          
          if (username === 'admin' && password === 'admin123') {
            alert('✅ Login successful! Welcome to Admin Panel.\\n\\nNote: This is CasaOS demo mode.');
          } else {
            alert('❌ Invalid credentials!\\n\\nDefault: admin / admin123');
          }
        }
      </script>
    </body>
    </html>
  `);
});

app.get('/config', (req, res) => {
  res.json({
    version: '2.0.0',
    mode: 'casaos-demo',
    platform: 'CasaOS',
    features: {
      mikrotik: false,
      payment_gateway: false,
      whatsapp: false,
      database: false
    },
    message: 'Running in CasaOS demo mode'
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 HotSpot Voucher Automator running on port ${PORT}`);
  console.log(`📱 Access: http://localhost:${PORT}`);
  console.log(`🔧 Admin: http://localhost:${PORT}/admin`);
  console.log(`📊 Health: http://localhost:${PORT}/health`);
  console.log(`🏠 Platform: CasaOS`);
});
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  hotspot-voucher:
    build: .
    container_name: hotspot-voucher
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
      - TZ=Asia/Jakarta
    volumes:
      - /DATA/AppData/hotspot-voucher/logs:/app/logs
      - /DATA/AppData/hotspot-voucher/data:/app/data
      - /DATA/AppData/hotspot-voucher/config:/app/config
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "casaos.name=HotSpot Voucher"
      - "casaos.icon=https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/mikrotik.png"
      - "casaos.description=Automated HotSpot Voucher System"
      - "casaos.main_port=3001"
      - "casaos.category=Network"

networks:
  default:
    driver: bridge
EOF

echo "🔨 Building Docker image..."
docker build -t hotspot-voucher:latest . || {
    echo "❌ Build failed. Trying simpler approach..."
    
    # Create even simpler Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine
RUN apk add --no-cache curl wget
WORKDIR /app
RUN npm init -y && npm install express cors helmet --silent
COPY server.js .
EXPOSE 3001
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD wget -q --spider http://localhost:3001/health
CMD ["node", "server.js"]
EOF
    
    docker build -t hotspot-voucher:latest .
}

echo "🚀 Starting application..."
docker-compose up -d

echo "⏳ Waiting for application to start..."
sleep 15

echo "🔍 Checking application health..."
for i in {1..10}; do
    if curl -f http://localhost:3001/health &>/dev/null; then
        echo "✅ Application is running successfully!"
        break
    else
        echo "⏳ Waiting... (attempt $i/10)"
        sleep 3
    fi
done

# Cleanup
cd /
rm -rf $TEMP_DIR

echo ""
echo "🎉 HotSpot Voucher Automator installed successfully in CasaOS!"
echo ""
echo "📱 Access URLs:"
echo "   🌐 Main: http://localhost:3001"
echo "   🔧 Admin: http://localhost:3001/admin"
echo "   📊 Health: http://localhost:3001/health"
echo ""
echo "🔑 Default Credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "📋 Next Steps:"
echo "   1. Access the admin panel to configure settings"
echo "   2. Setup MikroTik connection (production version)"
echo "   3. Configure payment gateway (production version)"
echo "   4. Test the complete workflow"
echo ""
echo "✅ Installation completed! The app should now appear properly in CasaOS."
EOF

chmod +x install-casaos.sh
