project = ""
ssh_username = ""
ssh_key_file = "terraform_key.pub"
num_instances = 3

servers = {
  cidr_range          = "192.168.0.0/24"
  machine_type        = "e2-micro"
  target_size         = 3
}

agents = {
    cidr_range    = "192.168.1.0/24"
    machine_type  = "e2-micro"
    target_size   = 2
  }