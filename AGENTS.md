# AGENTS.md

## 🧠 System Role

You are a DevOps automation agent responsible for provisioning infrastructure and configuring a complete monitoring stack on Google Cloud Platform (GCP) using Terraform and Docker-based services.

---

## 🎯 Objectives

1. Provision a VM instance on GCP using Terraform.
2. Install and configure Nginx to serve a static HTML page.
3. Implement monitoring using:

   * Node Exporter
   * Prometheus
   * Grafana
4. Configure alerting for high memory usage.
5. Send alerts to Discord via webhook.
6. Deploy Uptime Kuma for web monitoring.
7. Send downtime alerts to Discord.

---

## ⚙️ Constraints & Requirements

* Use **Terraform (GCP provider)** for all infrastructure provisioning.
* Use **Docker / Docker Compose** for monitoring stack.
* Use **Ubuntu 22.04** as VM OS.
* Use **static external IP**.
* Ensure idempotent and reproducible deployment.
* Expose only required ports.

---

## 🏗️ Architecture Overview

* GCP Compute Engine VM
* Nginx (port 80)
* Node Exporter (port 9100)
* Prometheus (port 9090)
* Grafana (port 3000)
* Alertmanager (Discord webhook integration)
* Uptime Kuma (port 3001)

---

## 📁 Expected Project Structure

```bash
.
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── outputs.tf
├── provisioning/
│   └── setup.sh
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   ├── alert.rules.yml
│   └── alertmanager.yml
└── web/
    └── index.html
```

---

## 🚀 Execution Plan

### Step 1 — Provision Infrastructure

* Initialize Terraform
* Create:

  * VPC (optional or default)
  * Firewall rules (allow ports 22, 80, 3000, 9090, 9100, 3001)
  * Compute Engine VM (e2-micro recommended)

---

### Step 2 — Configure VM

Run `setup.sh` to:

* Install Docker & Docker Compose
* Install Nginx
* Enable services on boot

---

### Step 3 — Configure Web Server

Create file:

```bash
/var/www/html/index.html
```

Content:

```html
<h1>Hello, ini website pertama saya!</h1>
```

Restart:

```bash
sudo systemctl restart nginx
```

---

### Step 4 — Monitoring Stack

#### Node Exporter

* Collect system metrics
* Expose on port 9100

#### Prometheus

* Scrape Node Exporter
* Load alert rules

#### Grafana

* Connect to Prometheus
* Provide dashboards

---

### Step 5 — Prometheus Configuration

#### prometheus.yml

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

---

### Step 6 — Alert Rule (Memory Usage)

```yaml
groups:
- name: memory-alerts
  rules:
  - alert: HighMemoryUsage
    expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.8
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 80%"
```

---

### Step 7 — Alertmanager (Discord Integration)

```yaml
route:
  receiver: discord

receivers:
- name: discord
  webhook_configs:
  - url: 'https://discord.com/api/webhooks/1500863494621364336/c_Ts6EpFXAw6lE1OraPQ38DX6mZvq5h8wDiy64iRhLKKqpLTGUO0zBYtv0FDY2xTimPq'
```

---

### Step 8 — Uptime Kuma

* Deploy via Docker
* Monitor:

  * http://IP_VM
* Configure Discord notification using webhook

---

## ✅ Validation Checklist

* [ ] VM successfully created via Terraform
* [ ] Nginx accessible via public IP
* [ ] HTML page rendered correctly
* [ ] Prometheus collecting metrics
* [ ] Grafana dashboard operational
* [ ] Memory alert triggered correctly
* [ ] Discord receives alerts
* [ ] Uptime Kuma detects downtime
* [ ] Discord receives downtime alerts

---

## 🔐 Security Best Practices

* Use SSH keys only (disable password login)
* Restrict firewall rules to necessary ports
* Avoid exposing Prometheus publicly (optional improvement)
* Use environment variables for secrets (future improvement)

---

## 🧩 Failure Handling

* If Terraform fails → check IAM permissions
* If metrics missing → verify Node Exporter port
* If alerts fail → verify Alertmanager config
* If Discord fails → validate webhook URL

---

## 📌 Output Expectations

* Public IP of VM
* Accessible web server
* Working monitoring dashboards
* Verified alert delivery




---

## 📌 Notes

* Gunakan static IP di GCP
* Gunakan instance kecil (e.g., e2-micro untuk testing)
* Semua service bisa dijalankan via Docker Compose

---
PS D:\DigitalSkola\Task5> gcloud auth application-default login
Your browser has been opened to visit:

Credentials saved to file: [C:\Users\HP OMEN\AppData\Roaming\gcloud\application_default_credentials.json]

These credentials will be used by any library that requests Application Default Credentials (ADC).

Quota project "project-767a2e14-3a14-4b65-bc5" was added to ADC which can be used by Google client libraries for billing and quota. Note that some services may still bill the project owning the resource.