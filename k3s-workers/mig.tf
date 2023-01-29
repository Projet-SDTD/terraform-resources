data "template_file" "k3s-worker-startup-script" {
  template = file("${path.module}/templates/worker_init.sh")
  vars = {
    token          = var.token
    server_address = var.master_address
    project_id = var.project
  }
}

resource "google_compute_instance_template" "sdtd-k3s-worker" {
  name_prefix  = "sdtd-k3s-worker-"
  machine_type = var.machine_type
  can_ip_forward = true

  tags = ["k3s", "k3s-worker"]

  metadata_startup_script = data.template_file.k3s-worker-startup-script.rendered

  metadata = {
    ssh-keys = "${var.ssh_username}:${file("${path.module}/../${var.ssh_key_file}")}"
  }

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = var.sdtd-k3s-workers-disk-size
    device_name = "stateful-disk"
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

# Health check but for external LB (user -> master apiserver)
resource "google_compute_region_health_check" "sdtd-k3s-workers-mig-hc" {
  name   = "sdtd-k3s-workers-mig-hc"
  region = var.region

  timeout_sec        = 5
  check_interval_sec = 10
  unhealthy_threshold = 3

  tcp_health_check {
    port = 10250
  }
}

resource "google_compute_instance_group_manager" "sdtd-k3s-workers" {
  count = length(var.zones)
  name               = "sdtd-k3s-workers-${var.zones[count.index]}"
  base_instance_name = "sdtd-k3s-worker-${var.zones[count.index]}"
  zone = var.zones[count.index]

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
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    max_unavailable_fixed          = 1
    replacement_method             = "RECREATE"
  }

  stateful_disk {
    device_name = "stateful-disk"
    delete_rule = "ON_PERMANENT_INSTANCE_DELETION"
  }

  auto_healing_policies {
    health_check = google_compute_region_health_check.sdtd-k3s-workers-mig-hc.id
    initial_delay_sec = 600
  }

  depends_on = [google_compute_router_nat.sdtd-k3s-workers-nat]
}