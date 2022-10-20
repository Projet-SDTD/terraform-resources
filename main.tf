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
    ports = ["6443"]
  }
  target_tags = ["k3s-master"]
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

/* # Let's first work on masters right ?
module "k3s-agents" {
  source   = "./k3s-agents"
  for_each = var.agents

  project         = var.project
  network         = google_compute_network.k3s.self_link
  region          = var.region
  cidr_range      = var.workers.cidr_range
  machine_type    = var.workers.machine_type
  target_size     = var.workers.target_size
  token           = module.k3s-servers.token
  server_address  = module.k3s-servers.internal_lb_ip_address
  service_account = google_service_account.k3s-agent.email
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
     main_master_ip = google_compute_instance.sdtd-instance.0.network_interface.0.access_config.0.nat_ip,
     main_master_privateIP = google_compute_instance.sdtd-instance.0.network_interface.0.network_ip,
     masters_ips = slice(google_compute_instance.sdtd-instance, 1, length(google_compute_instance.sdtd-instance)).*.network_interface.0.access_config.0.nat_ip,
     masters_privateIPs = slice(google_compute_instance.sdtd-instance, 1, length(google_compute_instance.sdtd-instance)).*.network_interface.0.network_ip,
     workers_ips = [],
     workers_privateIPs = [],
    }
  )
  filename = "inventory"
}
*/