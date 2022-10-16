project = "green-jet-364012"
ssh_username = "leo"
ssh_key_file = "terraform_key.pub"
num_instances = 3
authorized_networks = "82.66.131.243/32"

# Provide multiple master sites
servers = {
  cidr_range          = "192.168.0.0/24"
  machine_type        = "e2-micro"
  target_size         = 2
}

# Provide multiple agent sites
agents = {
    cidr_range    = "192.168.1.0/24"
    machine_type  = "e2-micro"
    target_size   = 2
  }