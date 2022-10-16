# K3S token
output "token" {
  value = random_string.sdtd-k3s-token.result
}

# Internal apiserver LB address
output "internal_lb_ip_address" {
  value = google_compute_address.sdtd-k3s-api-internal.address
}