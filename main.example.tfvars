project = ""
ssh_username = ""
ssh_key_file = "terraform_key.pub"
authorized_networks = ""

servers = {
  cidr_range          = "192.168.0.0/24"
  machine_type        = "e2-medium"
  target_size         = 2
}

workers = {
    zones = ["europe-west9-a","europe-west9-b","europe-west9-c"]
    cidr_range    = "192.168.1.0/24"
    machine_type  = "e2-small"
    target_size   = 1
  }