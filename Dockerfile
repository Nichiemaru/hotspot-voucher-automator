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

# Create package.json with minimal dependencies
RUN cat > package.json << 'EOF' && \
{ \
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
    "helmet": "^7.1.0", \
    "pg": "^8.11.3", \
    "bcrypt": "^5.1.1", \
    "jsonwebtoken": "^9.0.2", \
    "axios": "^1.6.2" \
  } \
} \
EOF

# Install dependencies
RUN npm install --production --silent

# Create application server
RUN cat > server.js << 'EOF' && \
const express = require('express'); \
const cors = require('cors'); \
const helmet = require('helmet'); \
const path = require('path'); \
\
const app = express(); \
const PORT = process.env.PORT || 3001; \
\
// Middleware \
app.use(helmet({ contentSecurityPolicy: false })); \
app.use(cors()); \
app.use(express.json()); \
app.use(express.urlencoded({ extended: true })); \
\
// Health check \
app.get('/health', (req, res) => { \
  res.json({ \
    status: 'OK', \
    timestamp: new Date().toISOString(), \
    version: '2.0.0', \
    uptime: process.uptime() \
  }); \
}); \
\
// Main page \
app.get('/', (req, res) => { \
  res.send(\` \
    <!DOCTYPE html> \
    <html lang="id"> \
    <head> \
      <meta charset="UTF-8"> \
      <meta name="viewport" content="width=device-width, initial-scale=1.0"> \
      <title>HotSpot Voucher Automator</title> \
      <style> \
        * { margin: 0; padding: 0; box-sizing: border-box; } \
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; } \
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; } \
        .header { text-align: center; color: white; margin-bottom: 40px; } \
        .header h1 { font-size: 3rem; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); } \
        .header p { font-size: 1.2rem; opacity: 0.9; } \
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 40px; } \
        .card { background: white; border-radius: 15px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); transition: transform 0.3s ease; } \
        .card:hover { transform: translateY(-5px); } \
        .card h3 { color: #333; margin-bottom: 15px; font-size: 1.5rem; } \
        .card p { color: #666; line-height: 1.6; margin-bottom: 20px; } \
        .status { background: linear-gradient(45deg, #4CAF50, #45a049); color: white; padding: 15px; border-radius: 10px; text-align: center; margin: 20px 0; } \
        .button { display: inline-block; background: linear-gradient(45deg, #007bff, #0056b3); color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 10px; transition: all 0.3s ease; font-weight: bold; } \
        .button:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,123,255,0.4); } \
        .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; } \
        .feature { background: rgba(255,255,255,0.1); color: white; padding: 20px; border-radius: 10px; text-align: center; } \
        .feature-icon { font-size: 2rem; margin-bottom: 10px; } \
      </style> \
    </head> \
    <body> \
      <div class="container"> \
        <div class="header"> \
          <h1>🚀 HotSpot Voucher Automator</h1> \
          <p>Sistem Otomatis Penjualan Voucher Internet MikroTik</p> \
        </div> \
        \
        <div class="status"> \
          <h3>✅ Aplikasi Berhasil Berjalan!</h3> \
          <p><strong>Status:</strong> Online | <strong>Version:</strong> 2.0.0 | <strong>Port:</strong> 3001</p> \
        </div> \
        \
        <div class="cards"> \
          <div class="card"> \
            <h3>🎯 Fitur Utama</h3> \
            <p>Sistem otomatis untuk penjualan voucher internet dengan integrasi MikroTik RouterOS, payment gateway, dan notifikasi WhatsApp.</p> \
            <a href="/admin" class="button">🔧 Admin Panel</a> \
          </div> \
          \
          <div class="card"> \
            <h3>⚙️ Konfigurasi</h3> \
            <p>Setup koneksi MikroTik, payment gateway TriPay, dan WhatsApp gateway untuk sistem yang lengkap.</p> \
            <a href="/config" class="button">⚙️ Konfigurasi</a> \
          </div> \
          \
          <div class="card"> \
            <h3>📊 Monitoring</h3> \
            <p>Monitor transaksi, status voucher, dan performa sistem secara real-time.</p> \
            <a href="/health" class="button">📊 Health Check</a> \
          </div> \
        </div> \
        \
        <div class="features"> \
          <div class="feature"> \
            <div class="feature-icon">🔐</div> \
            <h4>Keamanan Tinggi</h4> \
            <p>Sistem autentikasi dan enkripsi data</p> \
          </div> \
          <div class="feature"> \
            <div class="feature-icon">⚡</div> \
            <h4>Proses Cepat</h4> \
            <p>Voucher otomatis dalam hitungan detik</p> \
          </div> \
          <div class="feature"> \
            <div class="feature-icon">📱</div> \
            <h4>WhatsApp Integration</h4> \
            <p>Notifikasi voucher langsung ke WhatsApp</p> \
          </div> \
          <div class="feature"> \
            <div class="feature-icon">💳</div> \
            <h4>Payment Gateway</h4> \
            <p>Integrasi dengan TriPay untuk pembayaran</p> \
          </div> \
        </div> \
      </div> \
    </body> \
    </html> \
  \`); \
}); \
\
// Admin panel \
app.get('/admin', (req, res) => { \
  res.send(\` \
    <!DOCTYPE html> \
    <html lang="id"> \
    <head> \
      <meta charset="UTF-8"> \
      <meta name="viewport" content="width=device-width, initial-scale=1.0"> \
      <title>Admin Panel - HotSpot Voucher</title> \
      <style> \
        body { font-family: Arial, sans-serif; margin: 0; background: #f5f5f5; } \
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; } \
        .container { max-width: 800px; margin: 20px auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); } \
        .form-group { margin: 20px 0; } \
        label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; } \
        input, select { width: 100%; padding: 12px; border: 2px solid #ddd; border-radius: 5px; font-size: 16px; } \
        input:focus, select:focus { border-color: #007bff; outline: none; } \
        .button { background: linear-gradient(45deg, #007bff, #0056b3); color: white; padding: 12px 24px; border: none; border-radius: 5px; cursor: pointer; width: 100%; font-size: 16px; font-weight: bold; } \
        .button:hover { background: linear-gradient(45deg, #0056b3, #004085); } \
        .alert { padding: 15px; margin: 20px 0; border-radius: 5px; } \
        .alert-info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; } \
        .alert-warning { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; } \
        .tabs { display: flex; margin-bottom: 20px; } \
        .tab { flex: 1; padding: 12px; background: #f8f9fa; border: 1px solid #ddd; cursor: pointer; text-align: center; } \
        .tab.active { background: #007bff; color: white; } \
        .tab-content { display: none; } \
        .tab-content.active { display: block; } \
      </style> \
    </head> \
    <body> \
      <div class="header"> \
        <h1>🔧 Admin Panel</h1> \
        <p>HotSpot Voucher Automator Management</p> \
      </div> \
      \
      <div class="container"> \
        <div class="alert alert-info"> \
          <strong>Demo Mode:</strong> Aplikasi berjalan dalam mode demo. Untuk konfigurasi lengkap, silakan deploy versi production dengan database. \
        </div> \
        \
        <div class="tabs"> \
          <div class="tab active" onclick="showTab('login')">Login</div> \
          <div class="tab" onclick="showTab('config')">Konfigurasi</div> \
          <div class="tab" onclick="showTab('status')">Status</div> \
        </div> \
        \
        <div id="login" class="tab-content active"> \
          <h3>🔐 Admin Login</h3> \
          <form onsubmit="handleLogin(event)"> \
            <div class="form-group"> \
              <label>Username:</label> \
              <input type="text" id="username" value="admin" required> \
            </div> \
            <div class="form-group"> \
              <label>Password:</label> \
              <input type="password" id="password" placeholder="admin123" required> \
            </div> \
            <button type="submit" class="button">🔑 Login</button> \
          </form> \
        </div> \
        \
        <div id="config" class="tab-content"> \
          <h3>⚙️ Konfigurasi Sistem</h3> \
          <div class="alert alert-warning"> \
            <strong>Perhatian:</strong> Konfigurasi ini memerlukan versi production dengan database PostgreSQL. \
          </div> \
          \
          <h4>🌐 MikroTik RouterOS</h4> \
          <div class="form-group"> \
            <label>IP Address:</label> \
            <input type="text" placeholder="192.168.1.1" disabled> \
          </div> \
          <div class="form-group"> \
            <label>Username:</label> \
            <input type="text" placeholder="admin" disabled> \
          </div> \
          \
          <h4>💳 Payment Gateway (TriPay)</h4> \
          <div class="form-group"> \
            <label>Merchant Code:</label> \
            <input type="text" placeholder="T42431" disabled> \
          </div> \
          \
          <h4>📱 WhatsApp Gateway</h4> \
          <div class="form-group"> \
            <label>API Endpoint:</label> \
            <input type="text" placeholder="https://api.whatsapp-gateway.com" disabled> \
          </div> \
        </div> \
        \
        <div id="status" class="tab-content"> \
          <h3>📊 Status Sistem</h3> \
          <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px;"> \
            <div style="background: #e8f5e8; padding: 20px; border-radius: 10px; text-align: center;"> \
              <h4>🟢 Web Server</h4> \
              <p>Online</p> \
            </div> \
            <div style="background: #fff3cd; padding: 20px; border-radius: 10px; text-align: center;"> \
              <h4>🟡 Database</h4> \
              <p>Demo Mode</p> \
            </div> \
            <div style="background: #f8d7da; padding: 20px; border-radius: 10px; text-align: center;"> \
              <h4>🔴 MikroTik</h4> \
              <p>Not Configured</p> \
            </div> \
            <div style="background: #f8d7da; padding: 20px; border-radius: 10px; text-align: center;"> \
              <h4>🔴 WhatsApp</h4> \
              <p>Not Configured</p> \
            </div> \
          </div> \
        </div> \
        \
        <div style="text-align: center; margin-top: 30px;"> \
          <a href="/" style="color: #007bff; text-decoration: none; font-weight: bold;">← Kembali ke Beranda</a> \
        </div> \
      </div> \
      \
      <script> \
        function showTab(tabName) { \
          document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active')); \
          document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active')); \
          event.target.classList.add('active'); \
          document.getElementById(tabName).classList.add('active'); \
        } \
        \
        function handleLogin(event) { \
          event.preventDefault(); \
          const username = document.getElementById('username').value; \
          const password = document.getElementById('password').value; \
          \
          if (username === 'admin' && password === 'admin123') { \
            alert('✅ Login berhasil! Selamat datang di Admin Panel.\\n\\nCatatan: Ini adalah mode demo. Untuk fitur lengkap, deploy versi production.'); \
          } else { \
            alert('❌ Username atau password salah!\\n\\nDefault: admin / admin123'); \
          } \
        } \
      </script> \
    </body> \
    </html> \
  \`); \
}); \
\
// Config endpoint \
app.get('/config', (req, res) => { \
  res.json({ \
    version: '2.0.0', \
    mode: 'demo', \
    features: { \
      mikrotik: false, \
      payment_gateway: false, \
      whatsapp: false, \
      database: false \
    }, \
    message: 'Deploy production version for full features' \
  }); \
}); \
\
// Error handling \
app.use((err, req, res, next) => { \
  console.error(err.stack); \
  res.status(500).json({ error: 'Something went wrong!' }); \
}); \
\
// 404 handler \
app.use('*', (req, res) => { \
  res.status(404).json({ error: 'Route not found' }); \
}); \
\
app.listen(PORT, '0.0.0.0', () => { \
  console.log(\`🚀 HotSpot Voucher Automator running on port \${PORT}\`); \
  console.log(\`📱 Access: http://localhost:\${PORT}\`); \
  console.log(\`🔧 Admin: http://localhost:\${PORT}/admin\`); \
  console.log(\`📊 Health: http://localhost:\${PORT}/health\`); \
}); \
EOF

# Create directories and set permissions
RUN mkdir -p logs data config uploads && \
    addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

CMD ["node", "server.js"]
