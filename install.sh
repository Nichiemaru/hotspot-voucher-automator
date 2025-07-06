#!/bin/bash

# ✅ SCRIPT INSTALASI OTOMATIS UNTUK CASAOS
echo "🚀 Installing HotSpot Voucher Automator..."

# Create directories
mkdir -p /DATA/AppData/hotspot-voucher/{logs,data,postgres}

# Set permissions
chmod 755 /DATA/AppData/hotspot-voucher
chmod 755 /DATA/AppData/hotspot-voucher/logs
chmod 755 /DATA/AppData/hotspot-voucher/data
chmod 755 /DATA/AppData/hotspot-voucher/postgres

# Download and setup
echo "📥 Downloading application..."
curl -L https://github.com/nichiemaru/hotspot-voucher-automator/archive/main.zip -o hotspot-voucher.zip
unzip hotspot-voucher.zip
cd hotspot-voucher-automator-main

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t hotspot-voucher:latest .

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check health
echo "🔍 Checking application health..."
curl -f http://localhost:3001/health

echo "✅ Installation completed!"
echo "🌐 Access your application at: http://localhost:3001"
echo "🔧 Admin panel: http://localhost:3001/admin"
echo "📚 Default credentials: admin / admin123"
