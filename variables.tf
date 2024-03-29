variable "project" {
    type = string
}

variable "credentials_file" {
    default = "credentials.json"
}

variable "region" {
    type = string
    default = "europe-west9"
}

variable "initial-master-zone" {
    default = "europe-west9-a"
}

variable servers {
    type = map
}

variable workers { }

variable "authorized_networks" {
  type = string
}

variable "sdtd-k3s-workers-disk-size" {}

variable "ssh_key_file" { }

variable "ssh_username" { }