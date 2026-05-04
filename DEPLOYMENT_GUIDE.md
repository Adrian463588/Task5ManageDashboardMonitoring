# GCP Monitoring Stack Deployment Guide

## Prerequisites

1. **GCP Account** with billing enabled
2. **gcloud CLI** installed and authenticated
3. **Terraform** installed (v1.0+)
4. **SSH key pair** generated (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)

## Step 1: Authenticate with GCP

```bash
gcloud auth application-default login
gcloud config set project [YOUR_PROJECT_ID]
```

## Step 2: Initialize Terraform

```bash
cd terraform
terraform init
```

## Step 3: Create Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"
region     = "asia-southeast2"
zone       = "asia-southeast2-a"
ssh_user   = "admin"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

## Step 4: Provision Infrastructure

```bash
terraform plan -out=plan.out
terraform apply plan.out
```

**Output:** Note the `vm_external_ip` from the output.

## Step 5: SSH into VM and Run Setup

```bash
ssh -i ~/.ssh/id_rsa admin@<VM_EXTERNAL_IP>
```

Once connected, the startup script will automatically run. If not, execute:

```bash
sudo bash /var/lib/google_scripts/setup.sh
```

## Step 6: Deploy Monitoring Stack

```bash
cd /opt/monitoring
docker compose up -d
```

## Step 7: Verify Services

```bash
docker ps
```

Expected containers:
- node-exporter (9100)
- prometheus (9090)
- alertmanager (9093)
- grafana (3000)
- uptime-kuma (3001)

## Step 8: Configure Grafana

### Access Grafana
1. Open: `http://<VM_IP>:3000`
2. Login: `admin` / `admin123`

### Add Prometheus Data Source
1. Settings → Data Sources → Add data source
2. Select: **Prometheus**
3. URL: `http://prometheus:9090`
4. Click: **Save & Test**

### Create Memory Usage Dashboard

**PromQL Query for Memory Usage:**
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Dashboard Panels:**
1. **Memory Usage Gauge**
   - Panel type: Gauge
   - Query: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
   - Field: 80 (threshold)

2. **Memory Usage Graph**
   - Panel type: Time series
   - Query: `node_memory_MemTotal_bytes` and `node_memory_MemAvailable_bytes`

### Configure Discord Alerting

1. **Create Contact Point:**
   - Alerting → Contact points → Add contact point
   - Name: `Discord`
   - Integration: **Discord**
   - Webhook URL: `https://discord.com/api/webhooks/1500863494621364336/c_Ts6EpFXAw6lE1OraPQ38DX6mZvq5h8wDiy64iRhLKKqpLTGUO0zBYtv0FDY2xTimPq`
   - Click: **Save contact point**

2. **Create Notification Policy:**
   - Alerting → Notification policies → New policy
   - Matcher: `severity == critical`
   - Contact point: `Discord`
   - Click: **Save**

## Step 9: Configure Uptime Kuma

### Access Uptime Kuma
1. Open: `http://<VM_IP>:3001`
2. Create admin account

### Add HTTP Monitor
1. Click: **Add New Monitor**
2. Monitor Type: **HTTP(s)**
3. Friendly Name: `Web Server`
4. URL: `http://<VM_IP>`
5. Heartbeat Interval: 30
6. Timeout: 10
7. Click: **Save**

### Configure Discord Notifications
1. Settings → Notifications → Add Notification
2. Type: **Discord**
3. Webhook URL: `https://discord.com/api/webhooks/1500863494621364336/c_Ts6EpFXAw6lE1OraPQ38DX6mZvq5h8wDiy64iRhLKKqpLTGUO0zBYtv0FDY2xTimPq`
4. Click: **Test** → **Save**

### Link to Monitor
1. Edit monitor → **Notifications**
2. Select Discord notification
3. Click: **Save**

## Step 10: Test Alerting

### Test Memory Alert
```bash
# On VM, simulate high memory usage
stress --cpu 8 --timeout 60
```

### Test Uptime Kuma Alert
```bash
# On VM, stop nginx
sudo systemctl stop nginx
```

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Web Server | `http://<VM_IP>` | - |
| Prometheus | `http://<VM_IP>:9090` | - |
| Grafana | `http://<VM_IP>:3000` | admin / admin123 |
| Alertmanager | `http://<VM_IP>:9093` | - |
| Uptime Kuma | `http://<VM_IP>:3001` | (create account) |

## Troubleshooting

### Check Container Status
```bash
docker compose -f /opt/monitoring/docker-compose.yml ps
```

### View Logs
```bash
docker logs -f node-exporter
docker logs -f prometheus
docker logs -f grafana
```

### Restart Service
```bash
docker compose -f /opt/monitoring/docker-compose.yml restart <service-name>
```

### Verify Prometheus Targets
1. Open: `http://<VM_IP>:9090/targets`
2. Ensure all targets are UP

### Check Firewall Rules
```bash
gcloud compute firewall-rules list --filter="allowed[].ports:22 OR allowed[].ports:80"
```

## Security Recommendations

1. **Change default passwords** in `docker-compose.yml`
2. **Restrict firewall** to specific IP ranges
3. **Use HTTPS** for Grafana and Prometheus (reverse proxy)
4. **Enable SSL** for web server (Let's Encrypt)
5. **Rotate Discord webhook** periodically

## File Structure

```
.
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   ├── alert.rules.yml
│   └── alertmanager.yml
├── provisioning/
│   └── setup.sh
├── web/
│   └── index.html
└── DEPLOYMENT_GUIDE.md
```