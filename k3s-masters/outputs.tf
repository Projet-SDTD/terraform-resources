# K3S token
output "token" {
  value = random_string.sdtd-k3s-token.result
}

# Internal apiserver LB address
output "internal_lb_ip_address" {
  value = google_compute_address.sdtd-k3s-api-internal.address
}

output "main_master_ip" {
  value = google_compute_instance_from_template.sdtd-k3s-init-master.network_interface.0.access_config.0.nat_ip
}

output "main_master_privateIP" {
  value =   google_compute_instance_from_template.sdtd-k3s-init-master.network_interface.0.network_ip
}

output "external_lb_ip_address" {
  value = google_compute_address.sdtd-k3s-api-external.address
}