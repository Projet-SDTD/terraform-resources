resource "random_string" "token" {
  length  = 32
  special = false
}

data "template_file" "k3s-first-master-startup-script" {
  template = file("${path.module}/templates/initial_master_init.sh")
  vars = {
    token                  = random_string.token.result
    internal_ip_address = google_compute_address.k3s-api-server-internal.address
    external_ip_address = google_compute_address.k3s-api-first-server-external.address
    external_lb_address = google_compute_address.k3s-api-server-external.address
  }
}

data "template_file" "k3s-master-startup-script" {
  template = file("${path.module}/templates/master_init.sh")
  vars = {
    token                  = random_string.token.result
    main_master_ip = google_compute_address.k3s-api-first-server-internal.address
  }
}

resource "google_compute_instance_template" "k3s-initial-master" {
  name_prefix  = "k3s-initial-master-"
  machine_type = var.machine_type

  tags = ["k3s", "k3s-master"]

  metadata_startup_script = data.template_file.k3s-first-master-startup-script.rendered

  metadata = {
    ssh-keys = "${var.ssh_username}:${file("${path.module}/${var.ssh_key_file}")}"
  }

  disk {
    source_image = "debian-cloud/debian-10"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.k3s-servers.id
    access_config {}
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  service_account {
    email = var.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_from_template" "k3s-init-master" {
  name = "k3s-init-master"
  zone = var.zone
  source_instance_template = google_compute_instance_template.k3s-initial-master.id
  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.k3s-servers.id
    network_ip = google_compute_address.k3s-api-first-server-internal.address
    access_config {
      nat_ip = google_compute_address.k3s-api-first-server-external.address
    }
  }
  
}

resource "google_compute_instance_template" "k3s-master" {
  name_prefix  = "k3s-master-"
  machine_type = var.machine_type

  tags = ["k3s", "k3s-master"]

  metadata_startup_script = data.template_file.k3s-master-startup-script.rendered

  metadata = {
    ssh-keys = "${var.ssh_username}:${file("${path.module}/${var.ssh_key_file}")}"
  }

  disk {
    source_image = "debian-cloud/debian-10"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.k3s-servers.id
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  service_account {
    email = var.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "k3s-masters" {
  name = "k3s-servers"

  base_instance_name = "k3s-server"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.k3s-master.id
  }

  target_size = var.target_size

  named_port {
    name = "k3s"
    port = 6443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.k3s-health-check-internal.id
    initial_delay_sec = 240
  }

  depends_on = [
    google_compute_instance_from_template.k3s-init-master,
    google_compute_router_nat.nat
  ]
}