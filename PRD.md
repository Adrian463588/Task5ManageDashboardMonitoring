# PRD.md (Product Requirements Document)

## 📌 Project Title

GCP-Based VM Monitoring and Web Server Observability System

---

## 🎯 Purpose

To design and deploy a fully observable web server environment on GCP with:

* Infrastructure as Code (Terraform)
* Real-time monitoring
* Automated alerting to Discord
* Uptime monitoring

---

## 👥 Target Users

* DevOps Engineers
* Cloud Engineers
* Students learning observability & infrastructure

---

## 🧩 Features

### 1. Infrastructure Provisioning

* Provision VM using Terraform (GCP)
* Assign static public IP
* Configure firewall rules

---

### 2. Web Server Deployment

* Install Nginx
* Serve static HTML page

**Acceptance Criteria:**

* Accessible via: `http://IP_VM`
* Displays:

```html
<h1>Hello, ini website pertama saya!</h1>
```

---

### 3. Monitoring System

#### Components

* Node Exporter → metric collection
* Prometheus → data aggregation
* Grafana → visualization

#### Metrics

* Memory usage (mandatory)
* CPU usage (optional)

---

### 4. Alerting System

* Trigger when memory usage exceeds threshold (80%)
* Use Prometheus Alertmanager

#### Notification Channel

* Discord Webhook

---

### 5. Uptime Monitoring

* Tool: Uptime Kuma
* Monitor HTTP endpoint

#### Alert Condition

* Website unreachable

#### Notification

* Send alert to Discord webhook

---

## ⚙️ Non-Functional Requirements

### Reliability

* Alert delivery < 60 seconds

### Performance

* Metrics refresh interval ≤ 15 seconds

### Security

* Minimal exposed ports
* SSH key authentication only

---

## 📊 Success Metrics

* Web server uptime ≥ 99%
* Alerts delivered successfully
* Monitoring dashboard operational
* Zero manual intervention after deployment

---

## 🧪 Test Plan

| Test Case            | Expected Result            |
| -------------------- | -------------------------- |
| Access VM IP         | Page loads correctly       |
| Stop Nginx           | Uptime Kuma triggers alert |
| Simulate high memory | Alert triggered            |
| Grafana access       | Dashboard visible          |
| Prometheus targets   | Healthy                    |

---

## 🚀 Deployment Workflow

1. Run Terraform → provision infrastructure
2. SSH into VM → run setup script
3. Deploy monitoring stack via Docker
4. Configure dashboards & alerts
5. Validate end-to-end system

---

## ⚠️ Risks & Mitigation

| Risk                    | Mitigation              |
| ----------------------- | ----------------------- |
| Misconfigured alerts    | Test with forced load   |
| Firewall blocking ports | Validate rules          |
| Resource constraints    | Use appropriate VM size |

---

## 🔮 Future Enhancements

* HTTPS with Let's Encrypt
* Centralized logging (ELK / Loki)
* Multi-node monitoring
* Auto-scaling infrastructure

---

## 🔗 External Integration

### Discord Webhook

```
https://discord.com/api/webhooks/1500863494621364336/c_Ts6EpFXAw6lE1OraPQ38DX6mZvq5h8wDiy64iRhLKKqpLTGUO0zBYtv0FDY2xTimPq
```

---

## ✅ Definition of Done

* Infrastructure provisioned via Terraform
* Web server accessible
* Monitoring fully operational
* Alerts successfully sent to Discord
* Uptime monitoring functional
* Documentation complete

---
