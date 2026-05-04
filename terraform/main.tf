resource "google_compute_instance" "vm_instance" {
  name         = "monitoring-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20240109"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_ip.address
      # Ephemeral IP will be assigned if nat_ip is not specified
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = file("${path.module}/../provisioning/setup.sh")

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  tags = ["monitoring", "webserver"]
}

resource "google_compute_address" "static_ip" {
  name = "monitoring-static-ip"
  region = var.region
}

resource "google_compute_firewall" "allow_monitoring" {
  name    = "allow-monitoring-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3000", "9090", "9100", "3001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["monitoring", "webserver"]
}