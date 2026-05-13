#!/bin/bash
# ==============================================================
# setup.sh — Monitoring VM Startup Script
# 
# Purpose : Install and run the full monitoring stack
# Services: Prometheus, Alertmanager, Grafana, Uptime Kuma
#
# Variables injected by Terraform templatefile():
#   - discord_webhook_url : Discord webhook for alert notifications
#   - target_vm_ip        : IP of the target VM to scrape metrics from
#   - monitoring_vm_ip    : IP of this monitoring VM
# ==============================================================

exec > /var/log/startup-script.log 2>&1
set -euo pipefail

echo "=== [monitoring-vm] Starting Monitoring Stack Setup ==="

# --------------------------------------------------------------
# 1. System: Swap + Packages
# --------------------------------------------------------------
echo "[1/5] Setting up swap and installing packages..."

fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io docker-compose

systemctl enable docker
systemctl start docker

# --------------------------------------------------------------
# 2. Create Monitoring Directory
# --------------------------------------------------------------
echo "[2/5] Creating monitoring directory structure..."
mkdir -p /opt/monitoring
cd /opt/monitoring

# --------------------------------------------------------------
# 3. Write Docker Compose (Single Responsibility per service)
# Note: node-exporter here monitors the monitoring-vm itself.
#       The target-vm node-exporter is scraped remotely by Prometheus.
# --------------------------------------------------------------
echo "[3/5] Writing docker-compose.yml..."

cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./alert.rules.yml:/etc/prometheus/alert.rules.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

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
    networks:
      - monitoring

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
    networks:
      - monitoring

  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - uptime-kuma_data:/app/data
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
  uptime-kuma_data:
COMPOSE_EOF

# --------------------------------------------------------------
# 4. Write Configuration Files
# Variables below are injected by Terraform templatefile()
# --------------------------------------------------------------
echo "[4/5] Writing Prometheus, Alertmanager config files..."

# prometheus.yml — Scrapes node-exporter on the target-vm
cat > prometheus.yml << 'PROM_EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/alert.rules.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  # Scrape node-exporter from the dedicated target VM
  - job_name: 'target-node'
    static_configs:
      - targets: ['TARGET_VM_IP_PLACEHOLDER:9100']
        labels:
          instance: 'target-vm'
PROM_EOF

# Inject target VM IP from Terraform into prometheus.yml
sed -i "s/TARGET_VM_IP_PLACEHOLDER/${target_vm_ip}/g" prometheus.yml

# alert.rules.yml — Exactly as per AGENTS.md spec, but formatted
cat > alert.rules.yml << 'RULES_EOF'
groups:
- name: memory-alerts
  rules:
  - alert: HighMemoryUsage
    expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.8
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "🚨 High Memory Usage pada {{ $labels.instance }}"
      description: "Peringatan! Penggunaan memori pada server {{ $labels.instance }} telah melewati batas 80%."
RULES_EOF

# alertmanager.yml — FIXED: Use discord_configs (not webhook_configs)
# discord_configs auto-formats the payload in Discord embed format
cat > alertmanager.yml << 'AM_EOF'
route:
  receiver: discord
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 1h

receivers:
- name: discord
  discord_configs:
  - webhook_url: 'DISCORD_WEBHOOK_PLACEHOLDER'
    title: '[{{ .Status | toUpper }}] Prometheus Alert'
    message: |-
      {{ range .Alerts }}
      **Alert:** {{ .Annotations.summary }}
      **Details:** {{ .Annotations.description }}
      **Severity:** {{ .Labels.severity }}
      {{ end }}
AM_EOF

# Inject Discord webhook URL from Terraform into alertmanager.yml
sed -i "s|DISCORD_WEBHOOK_PLACEHOLDER|${discord_webhook_url}|g" alertmanager.yml

# --------------------------------------------------------------
# 5. Launch Stack
# --------------------------------------------------------------
echo "[5/5] Launching monitoring stack with Docker Compose..."

docker-compose down 2>/dev/null || true
docker-compose pull
docker-compose up -d

echo "=== [monitoring-vm] Setup Complete ==="
echo "Prometheus : http://${monitoring_vm_ip}:9090"
echo "Grafana    : http://${monitoring_vm_ip}:3000"
echo "Alertmgr   : http://${monitoring_vm_ip}:9093"
echo "Uptime Kuma: http://${monitoring_vm_ip}:3001"