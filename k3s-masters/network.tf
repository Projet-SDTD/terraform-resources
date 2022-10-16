# Subnetwork in the VPC network for k3s masters
resource "google_compute_subnetwork" "sdtd-k3s-masters" {
  name          = "sdtd-k3s-masters"
  network       = var.network
  region        = var.region
  ip_cidr_range = var.cidr_range

  private_ip_google_access = true
}

# Private IP address to loadbalance/failover requests from workers to master apis
resource "google_compute_address" "sdtd-k3s-api-internal" {
  name         = "sdtd-k3s-api-internal"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  region       = var.region
  subnetwork   = google_compute_subnetwork.sdtd-k3s-masters.id
}

# Public IP address to loadbalance/failover requests from external to master apis (for example kubectl)
resource "google_compute_address" "sdtd-k3s-api-external" {
  name   = "sdtd-k3s-api-external"
  region = var.region
}

# Private IP address for the first master (with --cloud-init option)
resource "google_compute_address" "sdtd-k3s-initial-master-internal" {
  name         = "sdtd-k3s-initial-api-internal"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  region       = var.region
  subnetwork   = google_compute_subnetwork.sdtd-k3s-masters.id
}

# Public IP address for the first master (with --cloud-init option)
resource "google_compute_address" "sdtd-k3s-initial-master-external" {
  name = "sdtd-k3s-initial-master-external"
}

# Router to enable nating traffic of masters which haven't public IPs
resource "google_compute_router" "sdtd-k3s-masters-router" {
  name    = "sdtd-k3s-masters-router"
  region  = var.region
  network = var.network
}

# NAT on top of previously created router
resource "google_compute_router_nat" "sdtd-k3s-masters-nat" {
  name                               = "sdtd-k3s-masters-nat"
  router                             = google_compute_router.sdtd-k3s-masters-router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.sdtd-k3s-masters.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}