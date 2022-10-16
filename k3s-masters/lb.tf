# Health check for internal LB (worker -> master apiserver)
resource "google_compute_health_check" "sdtd-k3s-api-hc-internal" {
  name = "sdtd-k3s-api-hc-internal"

  timeout_sec        = 5
  check_interval_sec = 15

  tcp_health_check {
    port = 6443
  }
}

# Health check but for external LB (user -> master apiserver)
resource "google_compute_region_health_check" "sdtd-k3s-api-hc-external" {
  name   = "sdtd-k3s-api-hc-external"
  region = var.region

  timeout_sec        = 2
  check_interval_sec = 10

  tcp_health_check {
    port = 6443
  }
}

# Backend service for internal LB (backends => masters MIG)
resource "google_compute_region_backend_service" "sdtd-k3s-api-internal" {
  name                  = "sdtd-k3s-api-internal"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_health_check.sdtd-k3s-api-hc-internal.id]
  backend {
    group = google_compute_region_instance_group_manager.sdtd-k3s-masters.instance_group
  }
}

# Forwarding rule for internal api LB
resource "google_compute_forwarding_rule" "sdtd-k3s-api-internal" {
  name                  = "sdtd-k3s-api-internal"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  allow_global_access   = false
  ip_address            = google_compute_address.sdtd-k3s-api-internal.address
  backend_service       = google_compute_region_backend_service.sdtd-k3s-api-internal.id
  ports                 = [6443]
  network               = var.network
  subnetwork            = google_compute_subnetwork.sdtd-k3s-masters.self_link
}

# Backend service for external LB (backend => masters MIG)
resource "google_compute_region_backend_service" "sdtd-k3s-api-external" {
  name                  = "sdtd-k3s-api-external"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.sdtd-k3s-api-hc-external.id]
  backend {
    group = google_compute_region_instance_group_manager.sdtd-k3s-masters.instance_group
  }
}

# Forwarding rule for external api LB
resource "google_compute_forwarding_rule" "sdtd-k3s-api-external" {
  name                  = "sdtd-k3s-api-external"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_address.sdtd-k3s-api-external.address
  backend_service       = google_compute_region_backend_service.sdtd-k3s-api-external.id
  port_range            = "6443-6443"
}
