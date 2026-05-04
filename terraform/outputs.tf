output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_address.static_ip.address
}

output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.vm_instance.name
}

output "vm_zone" {
  description = "Zone of the VM instance"
  value       = google_compute_instance.vm_instance.zone
}