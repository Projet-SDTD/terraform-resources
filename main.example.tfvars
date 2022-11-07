project = ""
ssh_username = "leo"
ssh_key_file = "terraform_key.pub"
num_instances = 3
authorized_networks = ""

# TODO : Provide multiple master sites
servers = {
  cidr_range          = "192.168.0.0/24"
  machine_type        = "e2-small"
  target_size         = 2
}

# TODO : Provide multiple agent sites
workers = {
    cidr_range    = "192.168.1.0/24"
    machine_type  = "e2-micro"
    target_size   = 2
    zones = ["europe-west9-a", "europe-west9-b", "europe-west9-c"]
  }