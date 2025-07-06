const express = require("express")
const cors = require("cors")
const helmet = require("helmet")
const compression = require("compression")
const path = require("path")

const app = express()
const PORT = process.env.PORT || 3001
const VERSION = "2.1.0"

// Middleware
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  }),
)
app.use(
  cors({
    origin: true,
    credentials: true,
  }),
)
app.use(compression())
app.use(express.json({ limit: "10mb" }))
app.use(express.urlencoded({ extended: true, limit: "10mb" }))

// Request logging
app.use((req, res, next) => {
  const timestamp = new Date().toISOString()
  console.log(`[${timestamp}] ${req.method} ${req.url} - ${req.ip}`)
  next()
})

// Health check endpoint
app.get("/health", (req, res) => {
  const uptime = process.uptime()
  const memUsage = process.memoryUsage()

  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    version: VERSION,
    uptime: Math.floor(uptime),
    memory: {
      used: Math.round(memUsage.heapUsed / 1024 / 1024) + " MB",
      total: Math.round(memUsage.heapTotal / 1024 / 1024) + " MB",
    },
    platform: "CasaOS",
    node_version: process.version,
    pid: process.pid,
  })
})

// Main page
app.get("/", (req, res) => {
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
    `)
})

// Admin panel and other endpoints continue...
// [Rest of server.js content continues as in the original file]
