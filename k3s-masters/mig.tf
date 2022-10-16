# K3S token (for nodes to authenticate to apiserver)
resource "random_string" "sdtd-k3s-token" {
  length  = 32
  special = false
}

# Template init script for initial master
data "template_file" "sdtd-k3s-initial-master-startup-script" {
  template = file("${path.module}/templates/initial_master_init.sh")
  vars = {
    token = random_string.sdtd-k3s-token.result
    internal_ip_address = google_compute_address.sdtd-k3s-api-internal.address
    external_ip_address = google_compute_address.sdtd-k3s-initial-master-external.address
    external_lb_address = google_compute_address.sdtd-k3s-api-external.address
  }
}

# Template init script for regular master
data "template_file" "sdtd-k3s-master-startup-script" {
  template = file("${path.module}/templates/master_init.sh")
  vars = {
    token = random_string.sdtd-k3s-token.result
    main_master_ip = google_compute_address.sdtd-k3s-initial-master-internal.address
  }
}

# Initial master instance template
resource "google_compute_instance_template" "sdtd-k3s-initial-master" {
  name_prefix  = "sdtd-k3s-initial-master-"
  machine_type = var.machine_type

  tags = ["k3s", "k3s-master"]

  metadata_startup_script = data.template_file.sdtd-k3s-initial-master-startup-script.rendered

  metadata = {
    ssh-keys = "${var.ssh_username}:${file("${path.module}/../${var.ssh_key_file}")}"
  }

  disk {
    source_image = "debian-cloud/debian-10"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.sdtd-k3s-masters.id
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

# Initial master instance
resource "google_compute_instance_from_template" "sdtd-k3s-init-master" {
  name = "sdtd-k3s-init-master"
  zone = var.zone
  source_instance_template = google_compute_instance_template.sdtd-k3s-initial-master.id
  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.sdtd-k3s-masters.id
    network_ip = google_compute_address.sdtd-k3s-initial-master-internal.address
    access_config {
      nat_ip = google_compute_address.sdtd-k3s-initial-master-external.address
    }
  }
  
}

# Regular master instance template
resource "google_compute_instance_template" "sdtd-k3s-master" {
  name_prefix  = "sdtd-k3s-master-"
  machine_type = var.machine_type

  tags = ["k3s", "k3s-master"]

  metadata_startup_script = data.template_file.sdtd-k3s-master-startup-script.rendered

  metadata = {
    ssh-keys = "${var.ssh_username}:${file("${path.module}/../${var.ssh_key_file}")}"
  }

  disk {
    source_image = "debian-cloud/debian-10"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.sdtd-k3s-masters.id
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

# Regular masters MIG (with autohealing)
resource "google_compute_region_instance_group_manager" "sdtd-k3s-masters" {
  name = "sdtd-k3s-masters"

  base_instance_name = "k3s-master"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.sdtd-k3s-master.id
  }

  target_size = var.target_size

  named_port {
    name = "k3s"
    port = 6443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.sdtd-k3s-api-hc-internal.id
    initial_delay_sec = 240
  }

  depends_on = [
    google_compute_instance_from_template.sdtd-k3s-init-master,
    google_compute_router_nat.sdtd-k3s-masters-nat
  ]
}