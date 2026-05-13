output "monitoring_vm_ip" {
  description = "External IP of the monitoring VM (Prometheus, Grafana, Alertmanager, Uptime Kuma)"
  value       = google_compute_address.monitoring_static_ip.address
}

output "target_vm_ip" {
  description = "External IP of the target VM (Nginx website, Node Exporter)"
  value       = google_compute_address.target_static_ip.address
}

output "monitoring_vm_name" {
  description = "Name of the monitoring VM"
  value       = google_compute_instance.monitoring_vm.name
}

output "target_vm_name" {
  description = "Name of the target VM"
  value       = google_compute_instance.target_vm.name
}

output "access_urls" {
  description = "Quick access URLs for all services"
  value = {
    website      = "http://${google_compute_address.target_static_ip.address}"
    grafana      = "http://${google_compute_address.monitoring_static_ip.address}:3000"
    prometheus   = "http://${google_compute_address.monitoring_static_ip.address}:9090"
    alertmanager = "http://${google_compute_address.monitoring_static_ip.address}:9093"
    uptime_kuma  = "http://${google_compute_address.monitoring_static_ip.address}:3001"
    node_exporter = "http://${google_compute_address.target_static_ip.address}:9100"
  }
}