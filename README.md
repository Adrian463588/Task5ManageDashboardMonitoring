# Task5ManageDashboardMonitoring

A complete DevOps monitoring stack deployment on Google Cloud Platform (GCP) featuring web server, observability, and alerting.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      GCP Compute Engine                      │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Docker Network                        ││
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐   ││
│  │  │   Nginx     │ │ Node Exporter│ │   Prometheus   │   ││
│  │  │   (80)      │ │   (9100)     │ │    (9090)      │   ││
│  │  └─────────────┘ └─────────────┘ └─────────────────┘   ││
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐   ││
│  │  │ Alertmanager│ │   Grafana   │ │   Uptime Kuma   │   ││
│  │  │   (9093)    │ │   (3000)    │ │    (3001)      │   ││
│  │  └─────────────┘ └─────────────┘ └─────────────────┘   ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## 📦 Components

| Component | Port | Description |
|-----------|------|-------------|
| Nginx | 80 | Web server serving static HTML |
| Node Exporter | 9100 | System metrics collection |
| Prometheus | 9090 | Time-series database & alerting |
| Alertmanager | 9093 | Alert routing to Discord |
| Grafana | 3000 | Visualization dashboards |
| Uptime Kuma | 3001 | HTTP monitoring & alerts |

## 🚀 Quick Start

### Prerequisites

- **GCP Account** with billing enabled
- **gcloud CLI** installed and configured
- **Terraform** v1.0+
- **SSH key pair** (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)

### Step 1: Authenticate with GCP

```bash
# Login to GCP
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
```

### Step 2: Configure Variables

Create `terraform/terraform.tfvars`:

```hcl
project_id            = "your-gcp-project-id"
region                = "asia-southeast2"
zone                  = "asia-southeast2-a"
ssh_user              = "admin"
ssh_public_key_path   = "~/.ssh/id_rsa.pub"
```

### Step 3: Provision Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan and apply
terraform plan -out=plan.out
terraform apply plan.out

# Note the VM external IP from output
```

### Step 4: Access the VM

```bash
ssh -i ~/.ssh/id_rsa admin@<VM_EXTERNAL_IP>
```

The `setup.sh` script runs automatically on first boot and:
- Installs Docker & Docker Compose
- Installs Nginx
- Deploys all monitoring services
- Configures web server

### Step 5: Verify Deployment

```bash
# Check running containers
docker ps

# Test web server
curl http://localhost

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

## 🔗 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Web Server | `http://<VM_IP>` | - |
| Prometheus | `http://<VM_IP>:9090` | - |
| Grafana | `http://<VM_IP>:3000` | admin / admin123 |
| Alertmanager | `http://<VM_IP>:9093` | - |
| Uptime Kuma | `http://<VM_IP>:3001` | (create account) |

## 📊 Monitoring Configuration

### Memory Usage Query (PromQL)

```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### Alert Rules

- **HighMemoryUsage**: Memory > 80% for 1 minute
- **HighCPUUsage**: CPU > 80% for 2 minutes
- **DiskSpaceLow**: Disk > 80% for 5 minutes
- **NodeDown**: Node Exporter unreachable

### Discord Webhook

```
https://discord.com/api/webhooks/1500863494621364336/c_Ts6EpFXAw6lE1OraPQ38DX6mZvq5h8wDiy64iRhLKKqpLTGUO0zBYtv0FDY2xTimPq
```

## 🛠️ Manual Commands

### Start/Stop Services

```bash
cd /opt/monitoring

# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart specific service
docker compose restart prometheus

# View logs
docker compose logs -f
```

### Update Monitoring Stack

```bash
cd /opt/monitoring
docker compose pull
docker compose up -d
```

### Test Alerts

```bash
# Simulate high memory usage
stress --cpu 8 --timeout 60

# Stop web server to trigger Uptime Kuma alert
sudo systemctl stop nginx
```

## 📁 Project Structure

```
.
├── terraform/
│   ├── main.tf           # VM, static IP, firewall rules
│   ├── provider.tf       # GCP provider configuration
│   ├── variables.tf      # Configurable variables
│   ├── outputs.tf        # VM IP output
│   └── terraform.tfvars  # YOUR VARIABLES (create this)
├── monitoring/
│   ├── docker-compose.yml    # All monitoring services
│   ├── prometheus.yml        # Metrics collection config
│   ├── alert.rules.yml       # Alert rules
│   └── alertmanager.yml      # Discord webhook routing
├── provisioning/
│   └── setup.sh          # VM initialization script
├── web/
│   └── index.html        # Static HTML content
├── DEPLOYMENT_GUIDE.md   # Detailed deployment guide
└── README.md             # This file
```

## 🔐 Security Notes

- Change default Grafana credentials (`admin/admin123`)
- Restrict firewall rules to specific IP ranges
- Use HTTPS with Let's Encrypt for production
- Rotate Discord webhook URL periodically
- Never commit `terraform.tfvars` to version control

## 📝 Troubleshooting

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

### Verify Prometheus Targets
Open: `http://<VM_IP>:9090/targets`

### Check Firewall Rules
```bash
gcloud compute firewall-rules list --filter="allowed[].ports:22 OR allowed[].ports:80"
```

## 📄 License

This project is for educational purposes. Use at your own risk.

## 👤 Author

Created for DevOps learning and demonstration.