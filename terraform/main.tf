# ==============================================================
# main.tf - GCP Monitoring Infrastructure (2-VM Architecture)
# 
# Architecture:
#   - monitoring-vm (e2-small): Prometheus, Grafana, Alertmanager, Uptime Kuma
#   - target-vm    (e2-micro) : Nginx, Node Exporter (target for monitoring)
# ==============================================================

# --------------------------------------------------------------
# Static IP Addresses
# --------------------------------------------------------------

resource "google_compute_address" "monitoring_static_ip" {
  name   = "monitoring-static-ip"
  region = var.region
}

resource "google_compute_address" "target_static_ip" {
  name   = "target-static-ip"
  region = var.region
}

# --------------------------------------------------------------
# VM: target-vm — Nginx + Node Exporter (stress test target)
# --------------------------------------------------------------

resource "google_compute_instance" "target_vm" {
  name         = "target-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.target_static_ip.address
    }
  }

  metadata_startup_script = file("${path.module}/../provisioning/setup-target.sh")

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  tags = ["target", "webserver"]
}

# --------------------------------------------------------------
# VM: monitoring-vm — Full Monitoring Stack
# Uses templatefile() to inject Discord URL + Target IP (DRY)
# --------------------------------------------------------------

resource "google_compute_instance" "monitoring_vm" {
  name         = "monitoring-vm"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.monitoring_static_ip.address
    }
  }

  # DRY: All dynamic values injected once here, not duplicated in scripts
  metadata_startup_script = templatefile("${path.module}/../provisioning/setup.sh", {
    discord_webhook_url = var.discord_webhook_url
    target_vm_ip        = google_compute_address.target_static_ip.address
    monitoring_vm_ip    = google_compute_address.monitoring_static_ip.address
  })

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  tags = ["monitoring"]

  # Ensure target VM is created first so its IP is available for templatefile
  depends_on = [google_compute_address.target_static_ip]
}

# --------------------------------------------------------------
# Firewall: target-vm — Only expose Nginx + Node Exporter
# --------------------------------------------------------------

resource "google_compute_firewall" "allow_target" {
  name    = "allow-target-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "9100"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["target", "webserver"]
}

# --------------------------------------------------------------
# Firewall: monitoring-vm — Expose all monitoring service ports
# --------------------------------------------------------------

resource "google_compute_firewall" "allow_monitoring" {
  name    = "allow-monitoring-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "3000", "9090", "9093", "9100", "3001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["monitoring"]
}