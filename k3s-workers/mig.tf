data "template_file" "k3s-worker-startup-script" {
  template = file("${path.module}/templates/worker_init.sh")
  vars = {
    token          = var.token
    server_address = var.master_address
  }
}

resource "google_compute_instance_template" "sdtd-k3s-worker" {
  name_prefix  = "sdtd-k3s-worker-"
  machine_type = var.machine_type

  tags = ["k3s", "k3s-worker"]

  metadata_startup_script = data.template_file.k3s-worker-startup-script.rendered

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
    subnetwork = google_compute_subnetwork.sdtd-k3s-workers.self_link
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  service_account {
    email = var.sdtd-k3s-workers-service-account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "sdtd-k3s-workers" {
  name               = "sdtd-k3s-workers"
  base_instance_name = "sdtd-k3s-worker"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.sdtd-k3s-worker.id
  }

  target_size = var.target_size

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
  }

  depends_on = [google_compute_router_nat.sdtd-k3s-workers-nat]
}