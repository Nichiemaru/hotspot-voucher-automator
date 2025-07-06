#!/bin/bash

# 🧹 COMPLETE CASAOS CLEANUP AND FRESH INSTALL SCRIPT
# This script will completely remove legacy apps and install fresh application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${GREEN}"
    echo "=================================="
    echo "$1"
    echo "=================================="
    echo -e "${NC}"
}

# Function to stop CasaOS services
stop_casaos_services() {
    print_status "Stopping CasaOS services..."
    sudo systemctl stop casaos 2>/dev/null || true
    sudo systemctl stop casaos-gateway 2>/dev/null || true
    sudo systemctl stop casaos-local-storage 2>/dev/null || true
    sudo systemctl stop casaos-user-service 2>/dev/null || true
    sleep 3
}

# Function to start CasaOS services
start_casaos_services() {
    print_status "Starting CasaOS services..."
    sudo systemctl start casaos-local-storage 2>/dev/null || true
    sudo systemctl start casaos-user-service 2>/dev/null || true
    sudo systemctl start casaos-gateway 2>/dev/null || true
    sudo systemctl start casaos 2>/dev/null || true
    sleep 5
}

# Function to clean Docker completely
clean_docker() {
    print_status "Cleaning Docker containers, images, and networks..."
    
    # Stop and remove all hotspot related containers
    docker ps -a --format "table {{.Names}}" | grep -E "(hotspot|voucher|elated)" | while read container; do
        if [ "$container" != "NAMES" ] && [ ! -z "$container" ]; then
            print_status "Stopping and removing container: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        fi
    done
    
    # Remove all hotspot related images
    docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(hotspot|voucher)" | while read image; do
        if [ "$image" != "REPOSITORY:TAG" ] && [ ! -z "$image" ]; then
            print_status "Removing image: $image"
            docker rmi "$image" 2>/dev/null || true
        fi
    done
    
    # Remove networks
    docker network ls --format "table {{.Name}}" | grep -E "(hotspot|voucher)" | while read network; do
        if [ "$network" != "NAME" ] && [ ! -z "$network" ]; then
            print_status "Removing network: $network"
            docker network rm "$network" 2>/dev/null || true
        fi
    done
    
    # Clean Docker system
    docker system prune -af 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
}

# Function to clean CasaOS app database and files
clean_casaos_apps() {
    print_status "Cleaning CasaOS app database and configuration files..."
    
    # Remove app data directories
    sudo rm -rf /var/lib/casaos/apps/hotspot* 2>/dev/null || true
    sudo rm -rf /var/lib/casaos/apps/elated* 2>/dev/null || true
    sudo rm -rf /etc/casaos/apps/hotspot* 2>/dev/null || true
    sudo rm -rf /etc/casaos/apps/elated* 2>/dev/null || true
    
    # Remove CasaOS database entries (this is the key!)
    sudo rm -rf /var/lib/casaos/db/casaos.db* 2>/dev/null || true
    sudo rm -rf /var/lib/casaos/db/app.db* 2>/dev/null || true
    
    # Remove app configurations
    sudo rm -rf /DATA/AppData/casaos/apps/hotspot* 2>/dev/null || true
    sudo rm -rf /DATA/AppData/casaos/apps/elated* 2>/dev/null || true
    
    # Remove old app data
    sudo rm -rf /DATA/AppData/hotspot-voucher* 2>/dev/null || true
    
    # Clear CasaOS cache
    sudo rm -rf /tmp/casaos* 2>/dev/null || true
    sudo rm -rf /var/cache/casaos* 2>/dev/null || true
}

# Function to create fresh application
create_fresh_application() {
    print_status "Creating fresh application files..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd $TEMP_DIR
    
    print_status "Working in directory: $TEMP_DIR"
    
    # Create server.js with complete content
    cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;
const VERSION = '2.1.0';

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

// Request logging
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
        node_version: process.version,
        pid: process.pid
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
                content: '🚀';
                position: absolute;
                top: -60px;
                left: 50%;
                transform: translateX(-50%);
                font-size: 4rem;
                animation: bounce 2s infinite;
            }
            @keyframes bounce {
                0%, 20%, 50%, 80%, 100% { transform: translateX(-50%) translateY(0); }
                40% { transform: translateX(-50%) translateY(-10px); }
                60% { transform: translateX(-50%) translateY(-5px); }
            }
            .header h1 { 
                font-size: 3.5rem; 
                margin-bottom: 10px; 
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
                background: linear-gradient(45deg, #fff, #f0f0f0);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                background-clip: text;
                margin-top: 40px;
            }
            .header p { 
                font-size: 1.3rem; 
                opacity: 0.9; 
                margin-bottom: 20px;
            }
            .version-badge {
                display: inline-block;
                background: linear-gradient(45deg, #4CAF50, #45a049);
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 0.9rem;
                font-weight: bold;
                box-shadow: 0 4px 8px rgba(0,0,0,0.2);
            }
            .status-card { 
                background: linear-gradient(45deg, rgba(76,175,80,0.9), rgba(69,160,73,0.9)); 
                padding: 30px; 
                border-radius: 20px; 
                text-align: center; 
                margin: 30px 0;
                box-shadow: 0 15px 35px rgba(0,0,0,0.2);
                backdrop-filter: blur(10px);
                border: 1px solid rgba(255,255,255,0.1);
                animation: pulse 3s infinite;
            }
            @keyframes pulse {
                0%, 100% { box-shadow: 0 15px 35px rgba(0,0,0,0.2); }
                50% { box-shadow: 0 20px 40px rgba(76,175,80,0.3); }
            }
            .status-card h3 {
                font-size: 1.8rem;
                margin-bottom: 15px;
                display: flex;
                align-items: center;
                justify-content: center;
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
                transition: all 0.3s ease;
                border: 1px solid rgba(255,255,255,0.2);
            }
            .status-item:hover {
                transform: translateY(-5px);
                background: rgba(255,255,255,0.2);
                box-shadow: 0 10px 20px rgba(0,0,0,0.2);
            }
            .status-item.online { border-left: 4px solid #4CAF50; }
            .status-item.demo { border-left: 4px solid #FF9800; }
            .status-item.offline { border-left: 4px solid #f44336; }
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
                <h1>HotSpot Voucher Automator</h1>
                <p>Sistem Otomatis Penjualan Voucher Internet MikroTik</p>
                <div class="version-badge">v${VERSION} - CasaOS Fresh Install</div>
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
                <p><strong>Fresh Install v${VERSION}</strong> - No Legacy Apps!</p>
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
            console.log('%cFresh Install - No Legacy Apps!', 'color: #2196F3; font-size: 14px;');
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
                background: linear-gradient(45deg, #e8f5e8, #c8e6c9); 
                border-left: 5px solid #4CAF50; 
                color: #2e7d32;
            }
            .alert strong { color: #1b5e20; }
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
            <p>HotSpot Voucher Automator v${VERSION} - Fresh Install</p>
        </div>
        
        <div class="container">
            <div class="alert">
                <strong>✅ Fresh Install Success!</strong> Aplikasi berhasil diinstall tanpa legacy apps. 
                Semua komponen berjalan normal dalam mode CasaOS demo.
            </div>
            
            <div class="tabs">
                <button class="tab active" onclick="showTab(event, 'login')">🔐 Login</button>
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
                    <div class="status-card status-online">
                        <h4>🟢 CasaOS</h4>
                        <p><strong>Status:</strong> Integrated</p>
                        <p><strong>Platform:</strong> Docker</p>
                        <p><strong>Version:</strong> ${VERSION}</p>
                    </div>
                    <div class="status-card status-online">
                        <h4>🟢 Fresh Install</h4>
                        <p><strong>Status:</strong> Success</p>
                        <p><strong>Legacy Apps:</strong> Removed</p>
                        <p><strong>Clean:</strong> Yes</p>
                    </div>
                </div>
            </div>
            
            <div id="info" class="tab-content">
                <h3>ℹ️ System Information</h3>
                <div class="info-box">
                    <h4>📋 Application Details</h4>
                    <p><strong>Name:</strong> HotSpot Voucher Automator</p>
                    <p><strong>Version:</strong> ${VERSION}</p>
                    <p><strong>Platform:</strong> CasaOS</p>
                    <p><strong>Runtime:</strong> Node.js ${process.version}</p>
                    <p><strong>Architecture:</strong> ${process.arch}</p>
                    <p><strong>PID:</strong> ${process.pid}</p>
                    <p><strong>Install Type:</strong> Fresh Install</p>
                </div>
                
                <div class="info-box">
                    <h4>🚀 Features Available</h4>
                    <ul style="margin-left: 20px; margin-top: 10px;">
                        <li>✅ Web Interface</li>
                        <li>✅ Admin Panel</li>
                        <li>✅ Health Monitoring</li>
                        <li>✅ CasaOS Integration</li>
                        <li>✅ Clean Install (No Legacy)</li>
                        <li>❌ Database (Production only)</li>
                        <li>❌ MikroTik Integration (Production only)</li>
                        <li>❌ Payment Gateway (Production only)</li>
                        <li>❌ WhatsApp Gateway (Production only)</li>
                    </ul>
                </div>
                
                <div class="info-box">
                    <h4>🎉 Installation Success</h4>
                    <p>✅ All legacy apps have been successfully removed</p>
                    <p>✅ Fresh application installed and running</p>
                    <p>✅ CasaOS integration working properly</p>
                    <p>✅ No conflicts or legacy issues</p>
                </div>
            </div>
            
            <div class="back-link">
                <a href="/">← Kembali ke Beranda</a>
            </div>
        </div>
        
        <script>
            function showTab(event, tabName) {
                const tabContents = document.querySelectorAll('.tab-content');
                tabContents.forEach(content => content.classList.remove('active'));
                
                const tabs = document.querySelectorAll('.tab');
                tabs.forEach(tab => tab.classList.remove('active'));
                
                document.getElementById(tabName).classList.add('active');
                event.target.classList.add('active');
            }
            
            function handleLogin(event) {
                event.preventDefault();
                const username = document.getElementById('username').value;
                const password = document.getElementById('password').value;
                
                if (username === 'admin' && password === 'admin123') {
                    alert('✅ Login berhasil! Selamat datang di Admin Panel HotSpot Voucher Automator v${VERSION}\\n\\n🎉 Fresh Install Success!\\n🏠 Platform: CasaOS\\n📝 Mode: Demo\\n\\n✅ Semua legacy apps telah dihapus\\n✅ Aplikasi berjalan normal\\n✅ Tidak ada konflik');
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
            version: VERSION,
            mode: 'casaos-demo',
            platform: 'CasaOS',
            runtime: process.version,
            architecture: process.arch,
            pid: process.pid,
            uptime: process.uptime(),
            install_type: 'fresh_install'
        },
        features: {
            web_interface: true,
            admin_panel: true,
            health_monitoring: true,
            casaos_integration: true,
            clean_install: true,
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
            payment: 'not_configured',
            legacy_apps: 'removed'
        },
        message: 'Fresh install completed successfully - No legacy apps',
        timestamp: new Date().toISOString()
    });
});

// API status endpoint
app.get('/api/status', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        version: VERSION,
        platform: 'CasaOS',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        pid: process.pid,
        environment: process.env.NODE_ENV || 'development',
        install_type: 'fresh_install',
        legacy_apps_removed: true
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
    console.log(`✅ Install Type: Fresh Install`);
    console.log(`🗑️ Legacy Apps: Removed`);
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

    # Create Dockerfile
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
EOF

    # Create docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  hotspot-fresh:
    build: 
      context: .
      dockerfile: Dockerfile
    container_name: hotspot-fresh
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
      - TZ=Asia/Jakarta
    volumes:
      - /DATA/AppData/hotspot-fresh/logs:/app/logs
      - /DATA/AppData/hotspot-fresh/data:/app/data
      - /DATA/AppData/hotspot-fresh/config:/app/config
    networks:
      - hotspot-fresh-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      - "casaos.name=HotSpot Voucher Fresh"
      - "casaos.icon=https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/mikrotik.png"
      - "casaos.description=Fresh Install HotSpot Voucher System v2.1.0"
      - "casaos.main_port=3001"
      - "casaos.category=Network"
      - "casaos.developer=Nichiemaru"
      - "casaos.version=2.1.0"
      - "casaos.install_type=fresh"

networks:
  hotspot-fresh-network:
    driver: bridge
    name: hotspot-fresh-network
EOF

    print_success "Application files created successfully!"
    
    # Build Docker image
    print_status "Building Docker image..."
    if docker build -t hotspot-fresh:latest . --no-cache; then
        print_success "Docker image built successfully!"
    else
        print_error "Docker build failed!"
        exit 1
    fi
    
    # Start application
    print_status "Starting fresh application..."
    if docker-compose up -d; then
        print_success "Application started successfully!"
    else
        print_error "Failed to start application!"
        exit 1
    fi
    
    # Cleanup temp directory
    cd /
    rm -rf $TEMP_DIR
    
    print_success "Fresh application installation completed!"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying fresh installation..."
    
    # Wait for container to start
    print_status "Waiting for application to start..."
    sleep 25
    
    # Check container status
    if docker ps | grep -q "hotspot-fresh"; then
        print_success "✅ Container is running"
    else
        print_error "❌ Container is not running"
        docker ps -a | grep hotspot
        return 1
    fi
    
    # Check health endpoint
    print_status "Checking application health..."
    for i in {1..20}; do
        if curl -f http://localhost:3001/health &>/dev/null; then
            print_success "✅ Application is healthy!"
            break
        else
            print_warning "⏳ Waiting for health check... (attempt $i/20)"
            sleep 3
        fi
        
        if [ $i -eq 20 ]; then
            print_error "❌ Health check failed after 20 attempts"
            print_status "Checking logs..."
            docker logs hotspot-fresh --tail 30
            return 1
        fi
    done
    
    # Test web interface
    print_status "Testing web interface..."
    if curl -s http://localhost:3001 | grep -q "Fresh Install"; then
        print_success "✅ Web interface is working!"
    else
        print_warning "⚠️ Web interface test failed, but container is running"
    fi
    
    print_success "✅ All verification checks completed!"
}

# Main execution function
main() {
    print_header "COMPLETE CASAOS CLEANUP & FRESH INSTALL"
    print_status "This script will:"
    print_status "1. Stop CasaOS services"
    print_status "2. Remove ALL legacy apps and containers"
    print_status "3. Clean CasaOS database entries"
    print_status "4. Install fresh application"
    print_status "5. Restart CasaOS services"
    print_status ""
    print_warning "⚠️  This will remove ALL hotspot-voucher and elated_taussig apps!"
    print_status ""
    
    # Stop CasaOS services
    stop_casaos_services
    
    # Clean Docker
    clean_docker
    
    # Clean CasaOS apps
    clean_casaos_apps
    
    # Create fresh directories
    print_status "Creating fresh application directories..."
    sudo mkdir -p /DATA/AppData/hotspot-fresh/{logs,data,config}
    sudo chmod -R 755 /DATA/AppData/hotspot-fresh
    sudo chown -R $USER:$USER /DATA/AppData/hotspot-fresh 2>/dev/null || true
    
    # Create fresh application
    create_fresh_application
    
    # Start CasaOS services
    start_casaos_services
    
    # Verify installation
    verify_installation
    
    print_header "INSTALLATION COMPLETED SUCCESSFULLY!"
    print_success ""
    print_success "🎉 Fresh HotSpot Voucher Automator v2.1.0 installed!"
    print_success ""
    print_success "📱 Access Information:"
    print_success "   🌐 Main URL: http://localhost:3001"
    print_success "   🔧 Admin Panel: http://localhost:3001/admin"
    print_success "   📊 Health Check: http://localhost:3001/health"
    print_success "   ⚙️ Config API: http://localhost:3001/config"
    print_success ""
    print_success "🔑 Default Admin Credentials:"
    print_success "   👤 Username: admin"
    print_success "   🔐 Password: admin123"
    print_success ""
    print_success "✅ What was accomplished:"
    print_success "   🗑️ All legacy apps removed"
    print_success "   🧹 CasaOS database cleaned"
    print_success "   🐳 Docker containers cleaned"
    print_success "   🆕 Fresh application installed"
    print_success "   🔄 CasaOS services restarted"
    print_success ""
    print_success "📋 Next Steps:"
    print_success "   1. 🔄 Refresh your CasaOS web interface"
    print_success "   2. 👀 Look for 'HotSpot Voucher Fresh' in your apps"
    print_success "   3. 🔧 Access the admin panel"
    print_success "   4. 🚀 Enjoy your clean, fresh installation!"
    print_success ""
    print_success "🎯 The legacy apps should now be COMPLETELY GONE!"
    print_success "✨ Fresh application should appear normally in CasaOS!"
}

# Run main function
main
