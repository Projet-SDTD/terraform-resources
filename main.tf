terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "sdtd-network" {
  name = "sdtd-network"
}

resource "google_compute_firewall" "sdtd-external" {
  name    = "sdtd-firewall-icmp-ssh"
  network = google_compute_network.sdtd-network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

}

resource "google_compute_firewall" "sdtd-firewall-internal" {
  name    = "sdtd-firewall-6443"
  network = google_compute_network.sdtd-network.name

  source_tags = ["k3s"]
  target_tags = ["k3s"]

  allow {
    protocol = "all"
  }

}

resource "google_service_account" "k3s-server" {
  account_id = "k3s-server"
}

resource "google_service_account" "k3s-agent" {
  account_id = "k3s-agent"
}

module "k3s-servers" {
  source = "./k3s-masters"

  project             = var.project
  network             = google_compute_network.sdtd-network.self_link
  region              = var.region
  cidr_range          = var.servers.cidr_range
  machine_type        = var.servers.machine_type
  target_size         = var.servers.target_size
  service_account     = google_service_account.k3s-server.email
  ssh_username        = var.ssh_username
  ssh_key_file        = var.ssh_key_file
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