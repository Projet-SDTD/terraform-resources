# Terraform confi
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
    }
  }
}

# Google configuration
provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region = var.region
}

# Create the VPC network
resource "google_compute_network" "sdtd-network" {
  name = "sdtd-network"
}

# Allow ssh and k3s apiserver access from authorized IPs (our public IP for example)
resource "google_compute_firewall" "sdtd-external" {
  name    = "sdtd-firewall-icmp-ssh"
  network = google_compute_network.sdtd-network.self_link
  source_ranges = split(",", var.authorized_networks)

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["22", "6443"]
  }

}

# Allow health check from google health checkers
resource "google_compute_firewall" "sdtd-allow-hc" {
  name = "sdtd-allow-hc"
  network = google_compute_network.sdtd-network.self_link
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  allow {
    protocol = "tcp"
    ports = ["6443", "10250"]
  }
  target_tags = ["k3s"]
  direction = "INGRESS"
}

# Allow all communications between k3s nodes (TODO : maybe we can reduce a little bit, by checking which ports are used by k3s)
resource "google_compute_firewall" "sdtd-firewall-internal" {
  name = "sdtd-firewall-6443"
  network = google_compute_network.sdtd-network.self_link

  source_tags = ["k3s"]
  target_tags = ["k3s"]

  allow {
    protocol = "all"
  }

}

# Service account for the initial master (with permissions to curl the gcp api and the kube api)
resource "google_service_account" "sdtd-k3s-initial-master" {
  account_id = "sdtd-k3s-initial-master"
}

# Service account for the other masters
resource "google_service_account" "sdtd-k3s-masters" {
  account_id = "sdtd-k3s-masters"
}

# Service account for the workers
resource "google_service_account" "sdtd-k3s-workers" {
  account_id = "sdtd-k3s-workers"
}

# Permissions to access the gcp for the initial master
resource "google_project_iam_member" "iam-sdtd-k3s-initial-master" {
  project = var.project
  role = "roles/owner"
  member = "serviceAccount:${google_service_account.sdtd-k3s-initial-master.email}"
}
# Permissions to access the gcp for masters
resource "google_project_iam_member" "iam-sdtd-k3s-masters" {
  project = var.project
  role = "roles/owner"
  member = "serviceAccount:${google_service_account.sdtd-k3s-masters.email}"
}
# Permissions to access the gcp for workers
resource "google_project_iam_member" "iam-sdtd-k3s-workers" {
  project = var.project
  role = "roles/owner"
  member = "serviceAccount:${google_service_account.sdtd-k3s-workers.email}"
}

# K3S masters creation
module "sdtd-k3s-masters" {
  source = "./k3s-masters"

  project = var.project
  network = google_compute_network.sdtd-network.self_link
  region = var.region
  zone = var.initial-master-zone
  cidr_range = var.servers.cidr_range
  machine_type = var.servers.machine_type
  target_size = var.servers.target_size
  sdtd-k3s-masters-service-account = google_service_account.sdtd-k3s-masters.email
  sdtd-k3s-initial-master-service-account = google_service_account.sdtd-k3s-initial-master.email
  ssh_username = var.ssh_username
  ssh_key_file = var.ssh_key_file
}

# K3S workers creation
module "sdtd-k3s-workers" {
  source = "./k3s-workers"

  project = var.project
  network = google_compute_network.sdtd-network.self_link
  token = module.sdtd-k3s-masters.token
  zones = var.workers.zones
  region = var.region
  cidr_range = var.workers.cidr_range
  machine_type = var.workers.machine_type
  master_address = module.sdtd-k3s-masters.internal_lb_ip_address
  target_size = var.workers.target_size
  sdtd-k3s-workers-service-account = google_service_account.sdtd-k3s-workers.email
  ssh_username = var.ssh_username
  ssh_key_file = var.ssh_key_file
  sdtd-k3s-workers-disk-size = var.sdtd-k3s-workers-disk-size
  depends_on = [module.sdtd-k3s-masters]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("templates/inventory.tmpl",
    {
     main_master_ip = module.sdtd-k3s-masters.main_master_ip,
     ssh_user = var.ssh_username,
     main_master_privateIP = module.sdtd-k3s-masters.main_master_privateIP,
     masters_lb_ip = module.sdtd-k3s-masters.external_lb_ip_address,
    }
  )
  filename = "inventory"
}