#!/bin/bash

set -e

echo "=== Starting VM Configuration ==="

# Update system
echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Nginx
echo "Installing Nginx..."
apt-get install -y nginx

# Enable services
echo "Enabling services..."
systemctl enable nginx
systemctl enable docker

# Create web directory and HTML file
echo "Creating web content..."
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<h1>Hello, ini website pertama saya!</h1>
EOF

# Configure Nginx
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# Restart Nginx
echo "Restarting Nginx..."
systemctl restart nginx

# Create monitoring directory
echo "Creating monitoring directory..."
mkdir -p /opt/monitoring

# Create docker-compose.yml for monitoring stack
cat > /opt/monitoring/docker-compose.yml << 'EOF'
version: '3.8'

services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./alert.rules.yml:/etc/prometheus/alert.rules.yml:ro
      - ./alertmanager.yml:/etc/prometheus/alertmanager.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
    depends_on:
      - node-exporter

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus

  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - uptime-kuma_data:/app/data
    environment:
      - UPTIME_KUMA_PORT=3001

volumes:
  prometheus_data:
  grafana_data:
  uptime-kuma_data:
EOF

# Copy monitoring configurations
echo "Copying monitoring configurations..."
cp /opt/monitoring/docker-compose.yml /opt/monitoring/prometheus.yml 2>/dev/null || true
cp /opt/monitoring/docker-compose.yml /opt/monitoring/alert.rules.yml 2>/dev/null || true
cp /opt/monitoring/docker-compose.yml /opt/monitoring/alertmanager.yml 2>/dev/null || true

# Start monitoring stack
echo "Starting monitoring stack..."
cd /opt/monitoring
docker compose up -d

echo "=== VM Configuration Complete ==="
echo "VM is ready with:"
echo "  - Nginx serving on port 80"
echo "  - Node Exporter on port 9100"
echo "  - Prometheus on port 9090"
echo "  - Alertmanager on port 9093"
echo "  - Grafana on port 3000"
echo "  - Uptime Kuma on port 3001"