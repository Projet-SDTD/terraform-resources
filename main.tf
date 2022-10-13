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

  source_ranges = ["10.128.0.0/9"]

  allow {
    protocol = "tcp"
  }

}

resource "google_compute_instance" "sdtd-instance" {
  count = var.num_instances
  name         = "sdtd-instance-${count.index + 1}"
  machine_type = "e2-medium"
  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_key_file)}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.sdtd-network.name
    access_config {}
  }
}

output "public_ip" {
  value = google_compute_instance.sdtd-instance.*.network_interface.0.access_config.0.nat_ip
}

output "private_ip" {
  value = google_compute_instance.sdtd-instance.*.network_interface.0.network_ip
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