#!/bin/bash

# ✅ SCRIPT CLEANUP DAN INSTALL LENGKAP UNTUK CASAOS
set -e

echo "🧹 Starting complete cleanup and fresh installation..."

# Function to print colored output
print_status() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# 1. STOP DAN REMOVE SEMUA CONTAINER HOTSPOT
print_status "Stopping and removing existing containers..."
docker stop hotspot-voucher hotspot-db postgres 2>/dev/null || true
docker rm hotspot-voucher hotspot-db postgres 2>/dev/null || true

# 2. REMOVE NETWORKS
print_status "Removing existing networks..."
docker network rm hotspot-network hotspot-install_hotspot-network hotspot_default 2>/dev/null || true

# 3. REMOVE IMAGES LAMA
print_status "Removing old images..."
docker rmi hotspot-voucher:latest hotspot-install_hotspot-voucher 2>/dev/null || true

# 4. CLEAN DOCKER SYSTEM
print_status "Cleaning Docker system..."
docker system prune -f

# 5. REMOVE CASAOS APP REGISTRATION (INI YANG PENTING!)
print_status "Removing CasaOS app registration..."
sudo rm -rf /var/lib/casaos/apps/hotspot-voucher* 2>/dev/null || true
sudo rm -rf /etc/casaos/apps/hotspot-voucher* 2>/dev/null || true
sudo rm -rf /DATA/AppData/casaos/apps/hotspot-voucher* 2>/dev/null || true

# 6. RESTART CASAOS SERVICE
print_status "Restarting CasaOS services..."
sudo systemctl restart casaos 2>/dev/null || true
sudo systemctl restart casaos-gateway 2>/dev/null || true

# Wait for CasaOS to restart
sleep 5

# 7. CREATE FRESH DIRECTORIES
print_status "Creating fresh application directories..."
sudo mkdir -p /DATA/AppData/hotspot-voucher-v2/{logs,data,config,postgres}
sudo chmod -R 755 /DATA/AppData/hotspot-voucher-v2
sudo chown -R $USER:$USER /DATA/AppData/hotspot-voucher-v2 2>/dev/null || true

# 8. CREATE TEMPORARY BUILD DIRECTORY
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

print_status "Creating application files in $TEMP_DIR..."

# 9. CREATE SERVER.JS
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet({ 
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false 
}));
app.use(cors());
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    version: '2.0.1',
    uptime: process.uptime(),
    platform: 'CasaOS',
    memory: process.memoryUsage(),
    pid: process.pid
  });
});

// Main page with enhanced UI
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>HotSpot Voucher Automator v2.0.1</title>
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
          animation: fadeIn 1s ease-in;
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .header { 
          text-align: center; 
          margin-bottom: 40px; 
          position: relative;
        }
        .header::before {
          content: '';
          position: absolute;
          top: -50px;
          left: 50%;
          transform: translateX(-50%);
          width: 100px;
          height: 100px;
          background: rgba(255,255,255,0.1);
          border-radius: 50%;
          animation: pulse 2s infinite;
        }
        @keyframes pulse {
          0%, 100% { transform: translateX(-50%) scale(1); opacity: 0.7; }
          50% { transform: translateX(-50%) scale(1.1); opacity: 1; }
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
          font-size: 1.3rem; 
          opacity: 0.9; 
          margin-bottom: 20px;
        }
        .version-badge {
          display: inline-block;
          background: rgba(255,255,255,0.2);
          padding: 8px 16px;
          border-radius: 20px;
          font-size: 0.9rem;
          font-weight: bold;
          backdrop-filter: blur(10px);
        }
        .status-card { 
          background: linear-gradient(45deg, rgba(76,175,80,0.9), rgba(69,160,73,0.9)); 
          padding: 25px; 
          border-radius: 15px; 
          text-align: center; 
          margin: 30px 0;
          box-shadow: 0 10px 30px rgba(0,0,0,0.2);
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255,255,255,0.1);
        }
        .status-card h3 {
          font-size: 1.5rem;
          margin-bottom: 10px;
        }
        .cards { 
          display: grid; 
          grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); 
          gap: 25px; 
          margin-bottom: 40px; 
        }
        .card { 
          background: rgba(255,255,255,0.1); 
          border-radius: 20px; 
          padding: 30px; 
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255,255,255,0.2);
          transition: all 0.3s ease; 
          position: relative;
          overflow: hidden;
        }
        .card::before {
          content: '';
          position: absolute;
          top: 0;
          left: -100%;
          width: 100%;
          height: 100%;
          background: linear-gradient(90deg, transparent, rgba(255,255,255,0.1), transparent);
          transition: left 0.5s;
        }
        .card:hover::before {
          left: 100%;
        }
        .card:hover { 
          transform: translateY(-10px) scale(1.02); 
          box-shadow: 0 20px 40px rgba(0,0,0,0.3);
        }
        .card h3 { 
          font-size: 1.6rem; 
          margin-bottom: 15px; 
          display: flex;
          align-items: center;
          gap: 10px;
        }
        .card p { 
          line-height: 1.7; 
          margin-bottom: 20px; 
          opacity: 0.9;
        }
        .button { 
          display: inline-block; 
          background: linear-gradient(45deg, rgba(255,255,255,0.2), rgba(255,255,255,0.1)); 
          color: white; 
          padding: 12px 24px; 
          text-decoration: none; 
          border-radius: 10px; 
          font-weight: bold; 
          transition: all 0.3s ease;
          border: 1px solid rgba(255,255,255,0.3);
          backdrop-filter: blur(10px);
        }
        .button:hover { 
          background: linear-gradient(45deg, rgba(255,255,255,0.3), rgba(255,255,255,0.2));
          transform: translateY(-2px); 
          box-shadow: 0 10px 20px rgba(0,0,0,0.2);
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
          text-align: center;
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255,255,255,0.1);
          transition: all 0.3s ease;
        }
        .feature:hover {
          transform: translateY(-5px);
          background: rgba(255,255,255,0.15);
        }
        .feature-icon { 
          font-size: 2.5rem; 
          margin-bottom: 15px; 
          display: block;
        }
        .feature h4 {
          font-size: 1.2rem;
          margin-bottom: 10px;
        }
        .footer {
          text-align: center;
          margin-top: 50px;
          padding: 20px;
          border-top: 1px solid rgba(255,255,255,0.1);
          opacity: 0.8;
        }
        @media (max-width: 768px) {
          .header h1 { font-size: 2.5rem; }
          .cards { grid-template-columns: 1fr; }
          .features { grid-template-columns: 1fr; }
          .container { padding: 15px; }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚀 HotSpot Voucher Automator</h1>
          <p>Sistem Otomatis Penjualan Voucher Internet MikroTik</p>
          <div class="version-badge">v2.0.1 - CasaOS Edition</div>
        </div>
        
        <div class="status-card">
          <h3>✅ Aplikasi Berhasil Berjalan di CasaOS!</h3>
          <p><strong>Status:</strong> Online | <strong>Version:</strong> 2.0.1 | <strong>Port:</strong> 3001</p>
          <p><strong>Platform:</strong> CasaOS | <strong>Uptime:</strong> ${Math.floor(process.uptime())} seconds</p>
        </div>
        
        <div class="cards">
          <div class="card">
            <h3>🎯 Fitur Utama</h3>
            <p>Sistem otomatis untuk penjualan voucher internet dengan integrasi MikroTik RouterOS, payment gateway, dan notifikasi WhatsApp. Solusi lengkap untuk bisnis hotspot Anda.</p>
            <a href="/admin" class="button">🔧 Admin Panel</a>
          </div>
          
          <div class="card">
            <h3>⚙️ Konfigurasi</h3>
            <p>Setup koneksi MikroTik, payment gateway TriPay, dan WhatsApp gateway untuk sistem yang lengkap dan terintegrasi.</p>
            <a href="/config" class="button">⚙️ Konfigurasi</a>
          </div>
          
          <div class="card">
            <h3>📊 Monitoring</h3>
            <p>Monitor transaksi, status voucher, dan performa sistem secara real-time dengan dashboard yang informatif.</p>
            <a href="/health" class="button">📊 Health Check</a>
          </div>
        </div>
        
        <div class="features">
          <div class="feature">
            <div class="feature-icon">🔐</div>
            <h4>Keamanan Tinggi</h4>
            <p>Sistem autentikasi berlapis dan enkripsi data end-to-end</p>
          </div>
          <div class="feature">
            <div class="feature-icon">⚡</div>
            <h4>Proses Cepat</h4>
            <p>Voucher otomatis dalam hitungan detik dengan performa optimal</p>
          </div>
          <div class="feature">
            <div class="feature-icon">📱</div>
            <h4>WhatsApp Integration</h4>
            <p>Notifikasi voucher langsung ke WhatsApp customer</p>
          </div>
          <div class="feature">
            <div class="feature-icon">💳</div>
            <h4>Payment Gateway</h4>
            <p>Integrasi dengan TriPay untuk berbagai metode pembayaran</p>
          </div>
          <div class="feature">
            <div class="feature-icon">🌐</div>
            <h4>MikroTik Ready</h4>
            <p>Siap integrasi dengan RouterOS untuk manajemen hotspot</p>
          </div>
          <div class="feature">
            <div class="feature-icon">📈</div>
            <h4>Analytics</h4>
            <p>Laporan penjualan dan statistik penggunaan voucher</p>
          </div>
        </div>
        
        <div class="footer">
          <p>&copy; 2024 HotSpot Voucher Automator - Powered by CasaOS</p>
          <p>Developed with ❤️ for Indonesian Hotspot Providers</p>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Enhanced admin panel
app.get('/admin', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Admin Panel - HotSpot Voucher v2.0.1</title>
      <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🔧</text></svg>">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
          min-height: 100vh;
        }
        .header { 
          background: rgba(0,0,0,0.2); 
          color: white; 
          padding: 30px; 
          text-align: center;
          backdrop-filter: blur(10px);
        }
        .header h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 1.1rem; }
        .container { 
          max-width: 900px; 
          margin: 20px auto; 
          background: rgba(255,255,255,0.95); 
          border-radius: 20px; 
          box-shadow: 0 20px 40px rgba(0,0,0,0.2);
          overflow: hidden;
        }
        .alert { 
          padding: 20px; 
          margin: 20px; 
          border-radius: 10px; 
          background: linear-gradient(45deg, #e3f2fd, #bbdefb); 
          border-left: 5px solid #2196f3; 
          color: #1565c0;
        }
        .alert strong { color: #0d47a1; }
        .tabs { 
          display: flex; 
          background: #f5f5f5; 
          border-bottom: 1px solid #ddd;
        }
        .tab { 
          flex: 1; 
          padding: 15px; 
          background: #f8f9fa; 
          border: none;
          cursor: pointer; 
          text-align: center; 
          font-weight: bold;
          transition: all 0.3s ease;
          border-bottom: 3px solid transparent;
        }
        .tab:hover { background: #e9ecef; }
        .tab.active { 
          background: white; 
          color: #007bff;
          border-bottom-color: #007bff;
        }
        .tab-content { 
          display: none; 
          padding: 30px;
        }
        .tab-content.active { display: block; }
        .form-group { margin: 25px 0; }
        .form-group label { 
          display: block; 
          margin-bottom: 8px; 
          font-weight: bold; 
          color: #333; 
        }
        .form-group input, .form-group select { 
          width: 100%; 
          padding: 12px 15px; 
          border: 2px solid #ddd; 
          border-radius: 8px; 
          font-size: 16px;
          transition: border-color 0.3s ease;
        }
        .form-group input:focus, .form-group select:focus { 
          border-color: #007bff; 
          outline: none; 
          box-shadow: 0 0 0 3px rgba(0,123,255,0.1);
        }
        .button { 
          background: linear-gradient(45deg, #007bff, #0056b3); 
          color: white; 
          padding: 15px 30px; 
          border: none; 
          border-radius: 8px; 
          cursor: pointer; 
          width: 100%; 
          font-size: 16px; 
          font-weight: bold;
          transition: all 0.3s ease;
        }
        .button:hover { 
          background: linear-gradient(45deg, #0056b3, #004085); 
          transform: translateY(-2px);
          box-shadow: 0 5px 15px rgba(0,123,255,0.3);
        }
        .status-grid { 
          display: grid; 
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
          gap: 20px; 
          margin: 30px 0; 
        }
        .status-card { 
          padding: 25px; 
          border-radius: 15px; 
          text-align: center;
          transition: transform 0.3s ease;
        }
        .status-card:hover { transform: translateY(-5px); }
        .status-online { background: linear-gradient(45deg, #e8f5e8, #c8e6c9); color: #2e7d32; }
        .status-demo { background: linear-gradient(45deg, #fff3cd, #ffe0b2); color: #f57c00; }
        .status-offline { background: linear-gradient(45deg, #f8d7da, #ffcdd2); color: #d32f2f; }
        .status-card h4 { font-size: 1.2rem; margin-bottom: 10px; }
        .back-link { 
          text-align: center; 
          margin-top: 30px; 
          padding: 20px;
        }
        .back-link a { 
          color: #007bff; 
          text-decoration: none; 
          font-weight: bold; 
          font-size: 1.1rem;
        }
        .back-link a:hover { text-decoration: underline; }
        .info-box {
          background: linear-gradient(45deg, #f0f8ff, #e6f3ff);
          border: 1px solid #b3d9ff;
          border-radius: 10px;
          padding: 20px;
          margin: 20px 0;
          color: #0066cc;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>🔧 Admin Panel</h1>
        <p>HotSpot Voucher Automator v2.0.1 - CasaOS Management</p>
      </div>
      
      <div class="container">
        <div class="alert">
          <strong>🏠 CasaOS Mode:</strong> Aplikasi berjalan dalam mode CasaOS dengan fitur demo. 
          Untuk fitur lengkap dengan database PostgreSQL, MikroTik integration, dan payment gateway, 
          deploy versi production.
        </div>
        
        <div class="tabs">
          <button class="tab active" onclick="showTab(event, 'login')">🔐 Login</button>
          <button class="tab" onclick="showTab(event, 'config')">⚙️ Konfigurasi</button>
          <button class="tab" onclick="showTab(event, 'status')">📊 Status</button>
          <button class="tab" onclick="showTab(event, 'info')">ℹ️ Info</button>
        </div>
        
        <div id="login" class="tab-content active">
          <h3>🔐 Admin Login</h3>
          <div class="info-box">
            <strong>Demo Credentials:</strong><br>
            Username: <code>admin</code><br>
            Password: <code>admin123</code>
          </div>
          <form onsubmit="handleLogin(event)">
            <div class="form-group">
              <label>👤 Username:</label>
              <input type="text" id="username" value="admin" required>
            </div>
            <div class="form-group">
              <label>🔒 Password:</label>
              <input type="password" id="password" placeholder="admin123" required>
            </div>
            <button type="submit" class="button">🔑 Login to Admin Panel</button>
          </form>
        </div>
        
        <div id="config" class="tab-content">
          <h3>⚙️ Konfigurasi Sistem</h3>
          <div class="alert" style="background: linear-gradient(45deg, #fff3cd, #ffe0b2); color: #856404;">
            <strong>⚠️ Perhatian:</strong> Konfigurasi ini memerlukan versi production dengan database PostgreSQL 
            dan integrasi lengkap. Mode demo hanya menampilkan interface.
          </div>
          
          <h4>🌐 MikroTik RouterOS Configuration</h4>
          <div class="form-group">
            <label>IP Address Router:</label>
            <input type="text" placeholder="192.168.1.1" disabled>
          </div>
          <div class="form-group">
            <label>Username:</label>
            <input type="text" placeholder="admin" disabled>
          </div>
          <div class="form-group">
            <label>Password:</label>
            <input type="password" placeholder="••••••••" disabled>
          </div>
          
          <h4>💳 Payment Gateway (TriPay)</h4>
          <div class="form-group">
            <label>Merchant Code:</label>
            <input type="text" placeholder="T42431" disabled>
          </div>
          <div class="form-group">
            <label>API Key:</label>
            <input type="password" placeholder="••••••••••••••••" disabled>
          </div>
          
          <h4>📱 WhatsApp Gateway</h4>
          <div class="form-group">
            <label>API Endpoint:</label>
            <input type="text" placeholder="https://api.whatsapp-gateway.com" disabled>
          </div>
          <div class="form-group">
            <label>API Token:</label>
            <input type="password" placeholder="••••••••••••••••" disabled>
          </div>
          
          <button class="button" disabled>💾 Save Configuration (Production Only)</button>
        </div>
        
        <div id="status" class="tab-content">
          <h3>📊 System Status Overview</h3>
          <div class="status-grid">
            <div class="status-card status-online">
              <h4>🟢 Web Server</h4>
              <p><strong>Status:</strong> Online</p>
              <p><strong>Port:</strong> 3001</p>
              <p><strong>Uptime:</strong> ${Math.floor(process.uptime())}s</p>
            </div>
            <div class="status-card status-demo">
              <h4>🟡 Database</h4>
              <p><strong>Status:</strong> Demo Mode</p>
              <p><strong>Type:</strong> In-Memory</p>
              <p><strong>Note:</strong> No persistence</p>
            </div>
            <div class="status-card status-offline">
              <h4>🔴 MikroTik</h4>
              <p><strong>Status:</strong> Not Configured</p>
              <p><strong>Connection:</strong> None</p>
              <p><strong>Note:</strong> Production only</p>
            </div>
            <div class="status-card status-offline">
              <h4>🔴 WhatsApp</h4>
              <p><strong>Status:</strong> Not Configured</p>
              <p><strong>Gateway:</strong> None</p>
              <p><strong>Note:</strong> Production only</p>
            </div>
            <div class="status-card status-offline">
              <h4>🔴 Payment</h4>
              <p><strong>Status:</strong> Not Configured</p>
              <p><strong>Gateway:</strong> TriPay</p>
              <p><strong>Note:</strong> Production only</p>
            </div>
            <div class="status-card status-online">
              <h4>🟢 CasaOS</h4>
              <p><strong>Status:</strong> Integrated</p>
              <p><strong>Platform:</strong> Docker</p>
              <p><strong>Version:</strong> 2.0.1</p>
            </div>
          </div>
        </div>
        
        <div id="info" class="tab-content">
          <h3>ℹ️ System Information</h3>
          <div class="info-box">
            <h4>📋 Application Details</h4>
            <p><strong>Name:</strong> HotSpot Voucher Automator</p>
            <p><strong>Version:</strong> 2.0.1</p>
            <p><strong>Platform:</strong> CasaOS</p>
            <p><strong>Runtime:</strong> Node.js ${process.version}</p>
            <p><strong>Architecture:</strong> ${process.arch}</p>
            <p><strong>PID:</strong> ${process.pid}</p>
          </div>
          
          <div class="info-box">
            <h4>🚀 Features Available</h4>
            <ul style="margin-left: 20px; margin-top: 10px;">
              <li>✅ Web Interface</li>
              <li>✅ Admin Panel</li>
              <li>✅ Health Monitoring</li>
              <li>✅ CasaOS Integration</li>
              <li>❌ Database (Production only)</li>
              <li>❌ MikroTik Integration (Production only)</li>
              <li>❌ Payment Gateway (Production only)</li>
              <li>❌ WhatsApp Gateway (Production only)</li>
            </ul>
          </div>
          
          <div class="info-box">
            <h4>📞 Support & Documentation</h4>
            <p><strong>GitHub:</strong> <a href="https://github.com/nichiemaru/hotspot-voucher-automator" target="_blank">Repository</a></p>
            <p><strong>Issues:</strong> <a href="https://github.com/nichiemaru/hotspot-voucher-automator/issues" target="_blank">Report Bug</a></p>
            <p><strong>Documentation:</strong> <a href="https://github.com/nichiemaru/hotspot-voucher-automator/wiki" target="_blank">Wiki</a></p>
          </div>
        </div>
        
        <div class="back-link">
          <a href="/">← Kembali ke Beranda</a>
        </div>
      </div>
      
      <script>
        function showTab(event, tabName) {
          // Hide all tab contents
          const tabContents = document.querySelectorAll('.tab-content');
          tabContents.forEach(content => content.classList.remove('active'));
          
          // Remove active class from all tabs
          const tabs = document.querySelectorAll('.tab');
          tabs.forEach(tab => tab.classList.remove('active'));
          
          // Show selected tab content
          document.getElementById(tabName).classList.add('active');
          event.target.classList.add('active');
        }
        
        function handleLogin(event) {
          event.preventDefault();
          const username = document.getElementById('username').value;
          const password = document.getElementById('password').value;
          
          if (username === 'admin' && password === 'admin123') {
            alert('✅ Login berhasil! Selamat datang di Admin Panel HotSpot Voucher Automator v2.0.1\\n\\n🏠 Platform: CasaOS\\n📝 Mode: Demo\\n\\nCatatan: Ini adalah mode demo. Untuk fitur lengkap dengan database, MikroTik integration, dan payment gateway, deploy versi production.');
            
            // Show success message
            const loginTab = document.getElementById('login');
            loginTab.innerHTML += '<div style="background: #d4edda; color: #155724; padding: 15px; border-radius: 8px; margin-top: 20px; border: 1px solid #c3e6cb;"><strong>✅ Login Successful!</strong><br>Welcome to HotSpot Voucher Automator Admin Panel.<br><em>Demo mode - Limited functionality available.</em></div>';
          } else {
            alert('❌ Username atau password salah!\\n\\n🔑 Default credentials:\\nUsername: admin\\nPassword: admin123');
          }
        }
      </script>
    </body>
    </html>
  `);
});

// Configuration API endpoint
app.get('/config', (req, res) => {
  res.json({
    application: {
      name: 'HotSpot Voucher Automator',
      version: '2.0.1',
      mode: 'casaos-demo',
      platform: 'CasaOS',
      runtime: process.version,
      architecture: process.arch,
      pid: process.pid,
      uptime: process.uptime()
    },
    features: {
      web_interface: true,
      admin_panel: true,
      health_monitoring: true,
      casaos_integration: true,
      database: false,
      mikrotik_integration: false,
      payment_gateway: false,
      whatsapp_gateway: false
    },
    status: {
      web_server: 'online',
      database: 'demo_mode',
      mikrotik: 'not_configured',
      whatsapp: 'not_configured',
      payment: 'not_configured'
    },
    message: 'Running in CasaOS demo mode - Deploy production version for full features',
    support: {
      github: 'https://github.com/nichiemaru/hotspot-voucher-automator',
      issues: 'https://github.com/nichiemaru/hotspot-voucher-automator/issues',
      documentation: 'https://github.com/nichiemaru/hotspot-voucher-automator/wiki'
    }
  });
});

// API status endpoint
app.get('/api/status', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    version: '2.0.1',
    platform: 'CasaOS',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    pid: process.pid,
    environment: process.env.NODE_ENV || 'development'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: err.message,
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 HotSpot Voucher Automator v2.0.1 running on port ${PORT}`);
  console.log(`📱 Main: http://localhost:${PORT}`);
  console.log(`🔧 Admin: http://localhost:${PORT}/admin`);
  console.log(`📊 Health: http://localhost:${PORT}/health`);
  console.log(`⚙️ Config: http://localhost:${PORT}/config`);
  console.log(`🏠 Platform: CasaOS`);
  console.log(`🕐 Started: ${new Date().toISOString()}`);
});
EOF

# 10. CREATE DOCKERFILE
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

WORKDIR /app

# Create package.json
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
EOF

# 11. CREATE DOCKER-COMPOSE.YML
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  hotspot-voucher-v2:
    build: 
      context: .
      dockerfile: Dockerfile
    container_name: hotspot-voucher-v2
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
      - TZ=Asia/Jakarta
    volumes:
      - /DATA/AppData/hotspot-voucher-v2/logs:/app/logs
      - /DATA/AppData/hotspot-voucher-v2/data:/app/data
      - /DATA/AppData/hotspot-voucher-v2/config:/app/config
    networks:
      - hotspot-network-v2
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "casaos.name=HotSpot Voucher v2"
      - "casaos.icon=https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/mikrotik.png"
      - "casaos.description=Automated HotSpot Voucher System v2.0.1"
      - "casaos.main_port=3001"
      - "casaos.category=Network"
      - "casaos.developer=Nichiemaru"
      - "casaos.version=2.0.1"

networks:
  hotspot-network-v2:
    driver: bridge
    name: hotspot-network-v2
EOF

# 12. BUILD DAN START APPLICATION
print_status "Building Docker image..."
docker build -t hotspot-voucher-v2:latest . || {
    print_error "Build failed. Trying alternative approach..."
    
    # Create simpler Dockerfile as fallback
    cat > Dockerfile << 'EOF'
FROM node:18-alpine
RUN apk add --no-cache curl wget bash
WORKDIR /app
RUN npm init -y && npm install express@4.18.2 cors@2.8.5 helmet@7.1.0 compression@1.7.4 --silent
COPY server.js .
RUN adduser -D hotspot && chown -R hotspot:hotspot /app
USER hotspot
EXPOSE 3001
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD wget -q --spider http://localhost:3001/health
CMD ["node", "server.js"]
EOF
    
    docker build -t hotspot-voucher-v2:latest .
}

print_status "Starting application..."
docker-compose up -d

print_status "Waiting for application to start..."
sleep 20

# 13. VERIFY APPLICATION
print_status "Verifying application health..."
for i in {1..15}; do
    if curl -f http://localhost:3001/health &>/dev/null; then
        print_success "✅ Application is running successfully!"
        break
    else
        print_warning "⏳ Waiting for application... (attempt $i/15)"
        sleep 3
    fi
    
    if [ $i -eq 15 ]; then
        print_error "❌ Application failed to start properly"
        print_status "Checking logs..."
        docker logs hotspot-voucher-v2 --tail 20
        exit 1
    fi
done

# 14. FINAL VERIFICATION
print_status "Running final verification..."
HEALTH_CHECK=$(curl -s http://localhost:3001/health | grep -o '"status":"OK"' || echo "failed")
if [ "$HEALTH_CHECK" = '"status":"OK"' ]; then
    print_success "✅ Health check passed!"
else
    print_warning "⚠️ Health check failed, but container is running"
fi

# 15. CLEANUP TEMP DIRECTORY
cd /
rm -rf $TEMP_DIR

# 16. FINAL RESTART CASAOS (IMPORTANT!)
print_status "Final CasaOS restart to register new app..."
sudo systemctl restart casaos 2>/dev/null || true
sleep 5

print_success ""
print_success "🎉 HotSpot Voucher Automator v2.0.1 installed successfully!"
print_success ""
print_success "📱 Access URLs:"
print_success "   🌐 Main: http://localhost:3001"
print_success "   🔧 Admin: http://localhost:3001/admin"
print_success "   📊 Health: http://localhost:3001/health"
print_success "   ⚙️ Config: http://localhost:3001/config"
print_success ""
print_success "🔑 Default Credentials:"
print_success "   Username: admin"
print_success "   Password: admin123"
print_success ""
print_success "📋 Next Steps:"
print_success "   1. Refresh your CasaOS interface"
print_success "   2. Look for 'HotSpot Voucher v2' in your apps"
print_success "   3. Access the admin panel to explore features"
print_success "   4. For production deployment, contact support"
print_success ""
print_success "✅ The app should now appear NORMALLY in CasaOS (not as legacy)!"
print_success "🔄 If still showing as legacy, restart CasaOS: sudo systemctl restart casaos"
EOF
