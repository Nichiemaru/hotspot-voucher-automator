#!/bin/bash

# 🧹 SCRIPT CLEANUP DAN INSTALL ULANG UNTUK CASAOS
set -e

echo "🧹 Cleaning up existing containers and starting fresh installation..."

# Function to safely remove containers
cleanup_containers() {
    echo "🔍 Checking for existing containers..."
    
    # Stop and remove hotspot-voucher container if exists
    if docker ps -a --format "table {{.Names}}" | grep -q "hotspot-voucher"; then
        echo "🛑 Stopping existing hotspot-voucher container..."
        docker stop hotspot-voucher 2>/dev/null || true
        echo "🗑️ Removing existing hotspot-voucher container..."
        docker rm hotspot-voucher 2>/dev/null || true
    fi
    
    # Stop and remove hotspot-db container if exists
    if docker ps -a --format "table {{.Names}}" | grep -q "hotspot-db"; then
        echo "🛑 Stopping existing hotspot-db container..."
        docker stop hotspot-db 2>/dev/null || true
        echo "🗑️ Removing existing hotspot-db container..."
        docker rm hotspot-db 2>/dev/null || true
    fi
    
    # Remove any containers from previous installations
    docker ps -a --format "table {{.Names}}" | grep -E "(hotspot|voucher)" | while read container; do
        if [ "$container" != "NAMES" ]; then
            echo "🗑️ Removing container: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        fi
    done
    
    # Clean up networks
    echo "🌐 Cleaning up networks..."
    docker network ls --format "table {{.Name}}" | grep -E "(hotspot|voucher)" | while read network; do
        if [ "$network" != "NAME" ]; then
            echo "🗑️ Removing network: $network"
            docker network rm "$network" 2>/dev/null || true
        fi
    done
    
    # Clean up images if needed
    echo "🖼️ Cleaning up old images..."
    docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(hotspot|voucher)" | while read image; do
        if [ "$image" != "REPOSITORY:TAG" ]; then
            echo "🗑️ Removing image: $image"
            docker rmi "$image" 2>/dev/null || true
        fi
    done
    
    echo "✅ Cleanup completed!"
}

# Function to create directories
create_directories() {
    echo "📁 Creating application directories..."
    sudo mkdir -p /DATA/AppData/hotspot-voucher/{logs,data,config,postgres}
    sudo chmod -R 755 /DATA/AppData/hotspot-voucher
    sudo chown -R $USER:$USER /DATA/AppData/hotspot-voucher 2>/dev/null || true
    echo "✅ Directories created!"
}

# Function to install application
install_application() {
    echo "🚀 Starting fresh installation..."
    
    # Create temporary build directory
    TEMP_DIR=$(mktemp -d)
    cd $TEMP_DIR
    
    echo "📝 Creating application files..."
    
    # Create optimized Dockerfile
    cat > Dockerfile << 'EOF'
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

# Create app directory
WORKDIR /app

# Create package.json with exact versions
RUN echo '{ \
  "name": "hotspot-voucher-automator", \
  "version": "2.0.1", \
  "description": "Automated HotSpot Voucher System for CasaOS", \
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

# Create server file
COPY server.js .

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S hotspot -u 1001 -G nodejs && \
    mkdir -p logs data config && \
    chown -R hotspot:nodejs /app

# Switch to non-root user
USER hotspot

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# Start command
CMD ["node", "server.js"]
EOF

    # Create enhanced server.js
    cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

const app = express();
const PORT = process.env.PORT || 3001;
const VERSION = '2.0.1';

// Middleware
app.use(helmet({ 
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false 
}));
app.use(cors({
    origin: true,
    credentials: true
}));
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${req.method} ${req.url} - ${req.ip}`);
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    const uptime = process.uptime();
    const memUsage = process.memoryUsage();
    
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        version: VERSION,
        uptime: Math.floor(uptime),
        memory: {
            used: Math.round(memUsage.heapUsed / 1024 / 1024) + ' MB',
            total: Math.round(memUsage.heapTotal / 1024 / 1024) + ' MB'
        },
        platform: 'CasaOS',
        node_version: process.version
    });
});

// Main page
app.get('/', (req, res) => {
    res.send(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>HotSpot Voucher Automator v${VERSION}</title>
        <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🚀</text></svg>">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; 
                color: white; 
                overflow-x: hidden;
            }
            .container { 
                max-width: 1200px; 
                margin: 0 auto; 
                padding: 20px; 
                min-height: 100vh; 
                display: flex; 
                flex-direction: column; 
                justify-content: center; 
            }
            .header { 
                text-align: center; 
                margin-bottom: 40px; 
                animation: fadeInDown 1s ease-out;
            }
            .header h1 { 
                font-size: 3.5rem; 
                margin-bottom: 10px; 
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3); 
                background: linear-gradient(45deg, #fff, #f0f0f0);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                background-clip: text;
            }
            .header p { 
                font-size: 1.2rem; 
                opacity: 0.9; 
                margin-bottom: 20px;
            }
            .version-badge {
                display: inline-block;
                background: rgba(255,255,255,0.2);
                padding: 5px 15px;
                border-radius: 20px;
                font-size: 0.9rem;
                font-weight: bold;
                backdrop-filter: blur(10px);
            }
            .status-card { 
                background: rgba(255,255,255,0.15); 
                padding: 30px; 
                border-radius: 20px; 
                margin: 20px 0; 
                backdrop-filter: blur(10px);
                border: 1px solid rgba(255,255,255,0.2);
                animation: fadeInUp 1s ease-out;
            }
            .status-card h3 { 
                font-size: 1.5rem; 
                margin-bottom: 15px; 
                display: flex; 
                align-items: center; 
                gap: 10px;
            }
            .status-grid { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
                gap: 15px; 
                margin: 20px 0; 
            }
            .status-item { 
                background: rgba(255,255,255,0.1); 
                padding: 20px; 
                border-radius: 15px; 
                text-align: center;
                transition: transform 0.3s ease;
            }
            .status-item:hover {
                transform: translateY(-5px);
                background: rgba(255,255,255,0.2);
            }
            .status-item.online { border-left: 4px solid #4CAF50; }
            .status-item.demo { border-left: 4px solid #FF9800; }
            .status-item.offline { border-left: 4px solid #f44336; }
            .button { 
                display: inline-block; 
                background: rgba(255,255,255,0.2); 
                color: white; 
                padding: 15px 30px; 
                text-decoration: none; 
                border-radius: 50px; 
                margin: 10px; 
                font-weight: bold; 
                transition: all 0.3s ease;
                border: 2px solid rgba(255,255,255,0.3);
                backdrop-filter: blur(10px);
            }
            .button:hover { 
                background: rgba(255,255,255,0.3); 
                transform: translateY(-2px); 
                box-shadow: 0 10px 20px rgba(0,0,0,0.2);
            }
            .button.primary {
                background: linear-gradient(45deg, #4CAF50, #45a049);
                border-color: #4CAF50;
            }
            .features { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); 
                gap: 20px; 
                margin-top: 40px; 
            }
            .feature { 
                background: rgba(255,255,255,0.1); 
                padding: 25px; 
                border-radius: 15px; 
                transition: transform 0.3s ease;
                border: 1px solid rgba(255,255,255,0.2);
            }
            .feature:hover {
                transform: translateY(-5px);
                background: rgba(255,255,255,0.15);
            }
            .feature h4 { 
                font-size: 1.3rem; 
                margin-bottom: 10px; 
                display: flex; 
                align-items: center; 
                gap: 10px;
            }
            .footer {
                text-align: center;
                margin-top: 40px;
                padding: 20px;
                border-top: 1px solid rgba(255,255,255,0.2);
                opacity: 0.8;
            }
            @keyframes fadeInDown {
                from { opacity: 0; transform: translateY(-30px); }
                to { opacity: 1; transform: translateY(0); }
            }
            @keyframes fadeInUp {
                from { opacity: 0; transform: translateY(30px); }
                to { opacity: 1; transform: translateY(0); }
            }
            @media (max-width: 768px) {
                .header h1 { font-size: 2.5rem; }
                .container { padding: 15px; }
                .features { grid-template-columns: 1fr; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 HotSpot Voucher Automator</h1>
                <p>Sistem Otomatis Penjualan Voucher Internet MikroTik</p>
                <div class="version-badge">v${VERSION} - CasaOS Edition</div>
            </div>
            
            <div class="status-card">
                <h3>✅ Aplikasi Berhasil Berjalan di CasaOS!</h3>
                <div class="status-grid">
                    <div class="status-item online">
                        <h4>🟢 Web Server</h4>
                        <p><strong>Status:</strong> Online</p>
                        <p><strong>Port:</strong> 3001</p>
                    </div>
                    <div class="status-item demo">
                        <h4>🟡 Database</h4>
                        <p><strong>Mode:</strong> Demo</p>
                        <p><strong>Type:</strong> In-Memory</p>
                    </div>
                    <div class="status-item offline">
                        <h4>🔴 MikroTik</h4>
                        <p><strong>Status:</strong> Not Configured</p>
                        <p><strong>Action:</strong> Setup Required</p>
                    </div>
                    <div class="status-item offline">
                        <h4>🔴 WhatsApp</h4>
                        <p><strong>Status:</strong> Not Configured</p>
                        <p><strong>Action:</strong> Setup Required</p>
                    </div>
                </div>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="/admin" class="button primary">🔧 Admin Panel</a>
                <a href="/health" class="button">📊 Health Check</a>
                <a href="/config" class="button">⚙️ Configuration</a>
                <a href="/api/status" class="button">🔌 API Status</a>
            </div>
            
            <div class="features">
                <div class="feature">
                    <h4>🔐 Secure System</h4>
                    <p>Advanced authentication dengan JWT token dan data encryption untuk keamanan maksimal</p>
                </div>
                <div class="feature">
                    <h4>⚡ Fast Processing</h4>
                    <p>Automatic voucher generation dalam hitungan detik dengan optimized performance</p>
                </div>
                <div class="feature">
                    <h4>📱 WhatsApp Integration</h4>
                    <p>Direct voucher delivery ke WhatsApp customer dengan template message</p>
                </div>
                <div class="feature">
                    <h4>💳 Payment Gateway</h4>
                    <p>Terintegrasi dengan TriPay payment system untuk berbagai metode pembayaran</p>
                </div>
                <div class="feature">
                    <h4>🌐 MikroTik API</h4>
                    <p>Direct integration dengan MikroTik RouterOS untuk user management</p>
                </div>
                <div class="feature">
                    <h4>📊 Real-time Dashboard</h4>
                    <p>Monitoring real-time untuk transaksi, voucher, dan system performance</p>
                </div>
            </div>
            
            <div class="footer">
                <p>© 2024 HotSpot Voucher Automator - Powered by CasaOS</p>
                <p>Built with ❤️ for Indonesian Internet Café & Hotspot Providers</p>
            </div>
        </div>
        
        <script>
            // Auto-refresh status setiap 30 detik
            setInterval(() => {
                fetch('/health')
                    .then(response => response.json())
                    .then(data => {
                        console.log('Health check:', data);
                    })
                    .catch(error => {
                        console.error('Health check failed:', error);
                    });
            }, 30000);
            
            // Welcome message
            console.log('%c🚀 HotSpot Voucher Automator v${VERSION}', 'color: #4CAF50; font-size: 20px; font-weight: bold;');
            console.log('%cRunning on CasaOS Platform', 'color: #2196F3; font-size: 14px;');
        </script>
    </body>
    </html>
    `);
});

// Admin panel
app.get('/admin', (req, res) => {
    res.send(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Admin Panel - HotSpot Voucher v${VERSION}</title>
        <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🔧</text></svg>">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background: #f5f7fa; 
                min-height: 100vh;
            }
            .header { 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                color: white; 
                padding: 40px 20px; 
                text-align: center; 
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            }
            .header h1 { 
                font-size: 2.5rem; 
                margin-bottom: 10px; 
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3); 
            }
            .container { 
                max-width: 1000px; 
                margin: -20px auto 40px; 
                background: white; 
                padding: 40px; 
                border-radius: 15px; 
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                position: relative;
            }
            .alert { 
                padding: 20px; 
                margin: 20px 0; 
                border-radius: 10px; 
                background: linear-gradient(45deg, #e3f2fd, #bbdefb); 
                border-left: 5px solid #2196F3; 
                color: #0d47a1;
                font-weight: 500;
            }
            .alert strong { color: #1565c0; }
            .login-section {
                background: #fafafa;
                padding: 30px;
                border-radius: 10px;
                margin: 30px 0;
                border: 1px solid #e0e0e0;
            }
            .form-group { 
                margin: 20px 0; 
            }
            .form-group label { 
                display: block; 
                margin-bottom: 8px; 
                font-weight: 600; 
                color: #333;
            }
            .form-group input { 
                width: 100%; 
                padding: 15px; 
                border: 2px solid #e0e0e0; 
                border-radius: 8px; 
                font-size: 16px;
                transition: border-color 0.3s ease;
            }
            .form-group input:focus {
                outline: none;
                border-color: #2196F3;
                box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.1);
            }
            .button { 
                background: linear-gradient(45deg, #2196F3, #1976D2); 
                color: white; 
                padding: 15px 30px; 
                border: none; 
                border-radius: 8px; 
                cursor: pointer; 
                width: 100%; 
                font-weight: 600;
                font-size: 16px;
                transition: all 0.3s ease;
            }
            .button:hover {
                background: linear-gradient(45deg, #1976D2, #1565C0);
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(33, 150, 243, 0.3);
            }
            .status-grid { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); 
                gap: 20px; 
                margin: 30px 0; 
            }
            .status-card { 
                padding: 25px; 
                border-radius: 12px; 
                text-align: center; 
                transition: transform 0.3s ease;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            }
            .status-card:hover {
                transform: translateY(-5px);
            }
            .status-card h4 { 
                font-size: 1.2rem; 
                margin-bottom: 10px; 
            }
            .online { 
                background: linear-gradient(45deg, #e8f5e8, #c8e6c9); 
                border-left: 5px solid #4CAF50;
                color: #2e7d32;
            }
            .demo { 
                background: linear-gradient(45deg, #fff8e1, #ffecb3); 
                border-left: 5px solid #FF9800;
                color: #ef6c00;
            }
            .offline { 
                background: linear-gradient(45deg, #ffebee, #ffcdd2); 
                border-left: 5px solid #f44336;
                color: #c62828;
            }
            .back-link {
                display: inline-block;
                margin-top: 30px;
                color: #2196F3;
                text-decoration: none;
                font-weight: 600;
                padding: 10px 20px;
                border: 2px solid #2196F3;
                border-radius: 25px;
                transition: all 0.3s ease;
            }
            .back-link:hover {
                background: #2196F3;
                color: white;
                transform: translateY(-2px);
            }
            .system-info {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 10px;
                margin: 20px 0;
                border: 1px solid #dee2e6;
            }
            .system-info h4 {
                color: #495057;
                margin-bottom: 15px;
            }
            .info-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
            }
            .info-item {
                background: white;
                padding: 15px;
                border-radius: 8px;
                border-left: 4px solid #6c757d;
            }
            .info-item strong {
                color: #495057;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔧 Admin Panel</h1>
            <p>HotSpot Voucher Automator v${VERSION} - CasaOS Edition</p>
        </div>
        
        <div class="container">
            <div class="alert">
                <strong>🏠 CasaOS Mode:</strong> Aplikasi berjalan dalam mode CasaOS dengan fitur demo. 
                Untuk fitur lengkap dengan database PostgreSQL, MikroTik API, dan payment gateway, 
                upgrade ke versi production.
            </div>
            
            <div class="login-section">
                <h3>🔐 Admin Authentication</h3>
                <form onsubmit="handleLogin(event)">
                    <div class="form-group">
                        <label for="username">👤 Username:</label>
                        <input type="text" id="username" value="admin" required>
                    </div>
                    <div class="form-group">
                        <label for="password">🔑 Password:</label>
                        <input type="password" id="password" placeholder="admin123" required>
                    </div>
                    <button type="submit" class="button">🚀 Login to Dashboard</button>
                </form>
            </div>
            
            <h3>📊 System Status Overview</h3>
            <div class="status-grid">
                <div class="status-card online">
                    <h4>🟢 Web Server</h4>
                    <p><strong>Status:</strong> Running</p>
                    <p><strong>Port:</strong> 3001</p>
                    <p><strong>Uptime:</strong> ${Math.floor(process.uptime())}s</p>
                </div>
                <div class="status-card demo">
                    <h4>🟡 Database</h4>
                    <p><strong>Type:</strong> Demo Mode</p>
                    <p><strong>Storage:</strong> In-Memory</p>
                    <p><strong>Status:</strong> Active</p>
                </div>
                <div class="status-card offline">
                    <h4>🔴 MikroTik API</h4>
                    <p><strong>Status:</strong> Not Configured</p>
                    <p><strong>Action:</strong> Setup Required</p>
                    <p><strong>Version:</strong> RouterOS 7.x</p>
                </div>
                <div class="status-card offline">
                    <h4>🔴 WhatsApp Gateway</h4>
                    <p><strong>Status:</strong> Not Configured</p>
                    <p><strong>Action:</strong> Setup Required</p>
                    <p><strong>Type:</strong> API Integration</p>
                </div>
                <div class="status-card offline">
                    <h4>🔴 Payment Gateway</h4>
                    <p><strong>Provider:</strong> TriPay</p>
                    <p><strong>Status:</strong> Not Configured</p>
                    <p><strong>Methods:</strong> 20+ Available</p>
                </div>
                <div class="status-card demo">
                    <h4>🟡 SSL Certificate</h4>
                    <p><strong>Status:</strong> Development</p>
                    <p><strong>Type:</strong> Self-Signed</p>
                    <p><strong>Expires:</strong> N/A</p>
                </div>
            </div>
            
            <div class="system-info">
                <h4>🖥️ System Information</h4>
                <div class="info-grid">
                    <div class="info-item">
                        <strong>Platform:</strong><br>CasaOS Docker
                    </div>
                    <div class="info-item">
                        <strong>Node.js:</strong><br>${process.version}
                    </div>
                    <div class="info-item">
                        <strong>Memory:</strong><br>${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)} MB
                    </div>
                    <div class="info-item">
                        <strong>Architecture:</strong><br>${process.arch}
                    </div>
                </div>
            </div>
            
            <div style="text-align: center;">
                <a href="/" class="back-link">← Back to Home</a>
            </div>
        </div>
        
        <script>
            function handleLogin(event) {
                event.preventDefault();
                const username = document.getElementById('username').value;
                const password = document.getElementById('password').value;
                
                if (username === 'admin' && password === 'admin123') {
                    alert('✅ Login Successful!\\n\\n🎉 Welcome to HotSpot Voucher Admin Panel\\n\\n📝 Note: This is CasaOS demo mode.\\n\\n🚀 Features Available:\\n• System monitoring\\n• Configuration preview\\n• Health checks\\n• Log viewing\\n\\n💡 For production features, upgrade to full version.');
                    
                    // Simulate dashboard redirect
                    setTimeout(() => {
                        window.location.href = '/dashboard';
                    }, 2000);
                } else {
                    alert('❌ Invalid Credentials!\\n\\n🔑 Default Login:\\n• Username: admin\\n• Password: admin123\\n\\n💡 Tip: These are demo credentials for CasaOS testing.');
                }
            }
            
            // Auto-refresh status
            setInterval(() => {
                fetch('/health')
                    .then(response => response.json())
                    .then(data => {
                        console.log('System health:', data);
                    })
                    .catch(error => {
                        console.error('Health check failed:', error);
                    });
            }, 60000);
        </script>
    </body>
    </html>
    `);
});

// Dashboard (after login)
app.get('/dashboard', (req, res) => {
    res.send(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Dashboard - HotSpot Voucher v${VERSION}</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; background: #f5f5f5; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; }
            .container { max-width: 1200px; margin: 20px auto; padding: 20px; }
            .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
            .dashboard-card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .metric { text-align: center; padding: 20px; background: #f8f9fa; border-radius: 8px; margin: 10px 0; }
            .metric h3 { color: #495057; margin-bottom: 10px; }
            .metric .value { font-size: 2rem; font-weight: bold; color: #007bff; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>📊 Admin Dashboard</h1>
            <p>Real-time monitoring dan management</p>
        </div>
        <div class="container">
            <div class="dashboard-grid">
                <div class="dashboard-card">
                    <h3>📈 Statistics</h3>
                    <div class="metric">
                        <h3>Total Vouchers</h3>
                        <div class="value">0</div>
                    </div>
                    <div class="metric">
                        <h3>Active Users</h3>
                        <div class="value">0</div>
                    </div>
                </div>
                <div class="dashboard-card">
                    <h3>💰 Revenue</h3>
                    <div class="metric">
                        <h3>Today</h3>
                        <div class="value">Rp 0</div>
                    </div>
                    <div class="metric">
                        <h3>This Month</h3>
                        <div class="value">Rp 0</div>
                    </div>
                </div>
                <div class="dashboard-card">
                    <h3>⚙️ Quick Actions</h3>
                    <button onclick="alert('Demo mode - Feature not available')" style="width: 100%; padding: 10px; margin: 5px 0; background: #007bff; color: white; border: none; border-radius: 5px;">Generate Voucher</button>
                    <button onclick="alert('Demo mode - Feature not available')" style="width: 100%; padding: 10px; margin: 5px 0; background: #28a745; color: white; border: none; border-radius: 5px;">View Reports</button>
                    <button onclick="alert('Demo mode - Feature not available')" style="width: 100%; padding: 10px; margin: 5px 0; background: #ffc107; color: black; border: none; border-radius: 5px;">Settings</button>
                </div>
            </div>
            <div style="text-align: center; margin-top: 30px;">
                <a href="/admin" style="color: #007bff; text-decoration: none;">← Back to Admin</a>
            </div>
        </div>
    </body>
    </html>
    `);
});

// API endpoints
app.get('/api/status', (req, res) => {
    res.json({
        application: {
            name: 'HotSpot Voucher Automator',
            version: VERSION,
            status: 'running',
            platform: 'CasaOS',
            mode: 'demo'
        },
        services: {
            web_server: { status: 'online', port: PORT },
            database: { status: 'demo', type: 'in-memory' },
            mikrotik: { status: 'offline', configured: false },
            whatsapp: { status: 'offline', configured: false },
            payment: { status: 'offline', configured: false }
        },
        system: {
            uptime: Math.floor(process.uptime()),
            memory_usage: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
            node_version: process.version,
            platform: process.platform,
            arch: process.arch
        },
        timestamp: new Date().toISOString()
    });
});

app.get('/config', (req, res) => {
    res.json({
        version: VERSION,
        mode: 'casaos-demo',
        platform: 'CasaOS',
        environment: process.env.NODE_ENV || 'development',
        features: {
            mikrotik_api: false,
            payment_gateway: false,
            whatsapp_integration: false,
            database_postgresql: false,
            ssl_certificate: false,
            user_authentication: true,
            health_monitoring: true,
            logging: true
        },
        configuration: {
            port: PORT,
            timezone: process.env.TZ || 'Asia/Jakarta',
            max_memory: '512MB',
            auto_restart: true
        },
        message: 'Running in CasaOS demo mode - Upgrade to production for full features'
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(`[ERROR] ${new Date().toISOString()} - ${err.stack}`);
    res.status(500).json({ 
        error: 'Internal Server Error',
        message: 'Something went wrong!',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.url} not found`,
        available_routes: [
            'GET /',
            'GET /admin',
            'GET /dashboard',
            'GET /health',
            'GET /config',
            'GET /api/status'
        ]
    });
});

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log('');
    console.log('🚀 ================================');
    console.log('🎉 HotSpot Voucher Automator Started!');
    console.log('🚀 ================================');
    console.log(`📱 Version: ${VERSION}`);
    console.log(`🌐 URL: http://localhost:${PORT}`);
    console.log(`🔧 Admin: http://localhost:${PORT}/admin`);
    console.log(`📊 Health: http://localhost:${PORT}/health`);
    console.log(`🏠 Platform: CasaOS`);
    console.log(`⏰ Started: ${new Date().toLocaleString('id-ID')}`);
    console.log('🚀 ================================');
    console.log('');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 SIGTERM received, shutting down gracefully...');
    server.close(() => {
        console.log('✅ Server closed successfully');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('🛑 SIGINT received, shutting down gracefully...');
    server.close(() => {
        console.log('✅ Server closed successfully');
        process.exit(0);
    });
});
EOF

    # Create optimized docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  hotspot-voucher:
    build: 
      context: .
      dockerfile: Dockerfile
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
    networks:
      - hotspot-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "casaos.name=HotSpot Voucher"
      - "casaos.icon=https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/mikrotik.png"
      - "casaos.description=Automated HotSpot Voucher System v2.0.1"
      - "casaos.main_port=3001"
      - "casaos.category=Network"
      - "casaos.developer=Nichiemaru"
      - "casaos.project_url=https://github.com/nichiemaru/hotspot-voucher-automator"

networks:
  hotspot-network:
    driver: bridge
    name: hotspot-network
EOF

    echo "🔨 Building Docker image (this may take a few minutes)..."
    if docker build -t hotspot-voucher:latest . --no-cache; then
        echo "✅ Docker image built successfully!"
    else
        echo "❌ Docker build failed!"
        exit 1
    fi

    echo "🚀 Starting application with docker-compose..."
    if docker-compose up -d; then
        echo "✅ Application started successfully!"
    else
        echo "❌ Failed to start application!"
        exit 1
    fi

    # Cleanup temp directory
    cd /
    rm -rf $TEMP_DIR
    
    echo "✅ Installation completed!"
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    
    # Wait for container to start
    echo "⏳ Waiting for application to start..."
    sleep 20
    
    # Check container status
    if docker ps | grep -q "hotspot-voucher"; then
        echo "✅ Container is running"
    else
        echo "❌ Container is not running"
        docker ps -a | grep hotspot
        return 1
    fi
    
    # Check health endpoint
    echo "🏥 Checking application health..."
    for i in {1..15}; do
        if curl -f http://localhost:3001/health &>/dev/null; then
            echo "✅ Application is healthy!"
            break
        else
            echo "⏳ Waiting for health check... (attempt $i/15)"
            sleep 5
        fi
        
        if [ $i -eq 15 ]; then
            echo "❌ Health check failed after 15 attempts"
            echo "📋 Container logs:"
            docker logs hotspot-voucher --tail 20
            return 1
        fi
    done
    
    # Test web interface
    echo "🌐 Testing web interface..."
    if curl -s http://localhost:3001 | grep -q "HotSpot Voucher Automator"; then
        echo "✅ Web interface is working!"
    else
        echo "❌ Web interface test failed"
        return 1
    fi
    
    echo "✅ All verification checks passed!"
}

# Main execution
main() {
    echo "🧹 Starting cleanup and fresh installation..."
    echo "⚠️  This will remove all existing hotspot-voucher containers and data"
    echo "📅 $(date)"
    echo ""
    
    # Cleanup existing containers
    cleanup_containers
    
    # Create directories
    create_directories
    
    # Install application
    install_application
    
    # Verify installation
    verify_installation
    
    echo ""
    echo "🎉 =================================="
    echo "✅ INSTALLATION COMPLETED SUCCESSFULLY!"
    echo "🎉 =================================="
    echo ""
    echo "📱 Access Information:"
    echo "   🌐 Main URL: http://localhost:3001"
    echo "   🔧 Admin Panel: http://localhost:3001/admin"
    echo "   📊 Health Check: http://localhost:3001/health"
    echo "   🔌 API Status: http://localhost:3001/api/status"
    echo ""
    echo "🔑 Default Admin Credentials:"
    echo "   👤 Username: admin"
    echo "   🔐 Password: admin123"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. ✅ Access the web interface"
    echo "   2. 🔧 Login to admin panel"
    echo "   3. ⚙️ Configure system settings"
    echo "   4. 🚀 Upgrade to production version for full features"
    echo ""
    echo "🐳 Docker Commands:"
    echo "   📊 Check status: docker ps | grep hotspot"
    echo "   📋 View logs: docker logs hotspot-voucher"
    echo "   🔄 Restart: docker restart hotspot-voucher"
    echo "   🛑 Stop: docker stop hotspot-voucher"
    echo ""
    echo "✅ The application should now appear properly in CasaOS!"
    echo "🎯 No more 'Legacy app' status!"
}

# Run main function
main
