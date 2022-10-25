resource "google_compute_subnetwork" "sdtd-k3s-workers" {
  name          = "sdtd-k3s-workers"
  network       = var.network
  region        = var.region
  ip_cidr_range = var.cidr_range

  private_ip_google_access = true
}

resource "google_compute_router" "sdtd-k3s-workers-router" {
  name    = "sdtd-k3s-workers"
  region  = var.region
  network = var.network
}

resource "google_compute_router_nat" "sdtd-k3s-workers-nat" {
  name                               = "sdtd-k3s-workers-nat"
  router                             = google_compute_router.sdtd-k3s-workers-router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.sdtd-k3s-workers.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}