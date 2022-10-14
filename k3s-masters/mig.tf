resource "random_string" "token" {
  length  = 32
  special = false
}

data "template_file" "k3s-server-startup-script" {
  template = file("${path.module}/templates/master_init.sh")
  vars = {
    token                  = random_string.token.result
    internal_lb_ip_address = google_compute_address.k3s-api-server-internal.address
    external_lb_ip_address = google_compute_address.k3s-api-server-internal.address
  }
}

resource "google_compute_instance_template" "k3s-master" {
  name_prefix  = "k3s-master-"
  machine_type = var.machine_type

  tags = ["k3s", "k3s-master"]

  metadata_startup_script = data.template_file.k3s-server-startup-script.rendered

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

  depends_on = [google_compute_router_nat.nat]
}