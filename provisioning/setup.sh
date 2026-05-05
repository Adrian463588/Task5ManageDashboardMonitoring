#!/bin/bash

exec > /var/log/startup-script.log 2>&1
set -x

echo "=== Starting Optimized VM Configuration ==="

# 1. Tambahkan SWAP File (Sangat Penting untuk RAM 1GB)
echo "Setting up 2GB swap file..."
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 2. Update & Install (Minimal)
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io docker-compose nginx

# 3. Optimasi Nginx
systemctl enable nginx
systemctl start nginx

# 4. Buat Docker Compose dengan Limit Memory
mkdir -p /opt/monitoring
cd /opt/monitoring

cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 50M
    ports:
      - "9100:9100"

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=1d'
      - '--storage.tsdb.retention.size=512MB'
    deploy:
      resources:
        limits:
          memory: 250M
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 250M
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123

  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 200M
    ports:
      - "3001:3001"
EOF

# 5. Prometheus Config
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 30s # Diperlama agar CPU lebih santai
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

# 6. Jalankan dengan paksa restart
docker-compose down || true
docker-compose up -d

echo "=== Configuration Complete ==="