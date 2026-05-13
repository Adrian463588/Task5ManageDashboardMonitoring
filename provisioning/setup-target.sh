#!/bin/bash
# ==============================================================
# setup-target.sh — Target VM Startup Script
#
# Purpose : Serve the website and expose system metrics
# Services: Nginx (port 80), Node Exporter (port 9100)
#
# Single Responsibility: This VM only serves as a monitoring
# target. All monitoring services are on monitoring-vm.
# ==============================================================

exec > /var/log/startup-script.log 2>&1
set -euo pipefail

echo "=== [target-vm] Starting Target VM Setup ==="

# --------------------------------------------------------------
# 1. System: Swap + Packages
# --------------------------------------------------------------
echo "[1/3] Setting up swap and installing packages..."

echo "Setting up 1GB swap file..."
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io nginx stress

systemctl enable docker
systemctl start docker

# --------------------------------------------------------------
# 2. Configure Nginx Web Server
# --------------------------------------------------------------
echo "[2/3] Configuring Nginx..."

systemctl enable nginx
systemctl start nginx

# Remove default Nginx page and serve custom HTML
rm -f /var/www/html/index.nginx-debian.html

cat > /var/www/html/index.html << 'HTML_EOF'
<h1>Hello, ini website pertama saya!</h1>
HTML_EOF

systemctl restart nginx

# --------------------------------------------------------------
# 3. Run Node Exporter via Docker
# Exposes system metrics on port 9100 for Prometheus to scrape
# --------------------------------------------------------------
echo "[3/3] Starting Node Exporter..."

docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --pid="host" \
  -p 9100:9100 \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  prom/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --path.rootfs=/rootfs \
  --collector.filesystem.mount-points-exclude='^/(sys|proc|dev|host|etc)($$|/)'

echo "=== [target-vm] Setup Complete ==="
echo "Website     : http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google')"
echo "Node Exporter: http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):9100"
