variable "project" { }

variable "credentials_file" {
    default = "credentials.json"
}

variable "region" {
    default = "europe-west9"
}

variable "zone" {
    default = "europe-west9-a"
}

variable "ssh_key_file" { }

variable "ssh_username" { }

variable num_instances { }