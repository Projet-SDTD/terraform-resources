variable "network" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "cidr_range" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "target_size" {
  type = number
  default = 2
}

variable "sdtd-k3s-masters-service-account" {
  type = string
}

variable "sdtd-k3s-initial-master-service-account" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_key_file" {
  type = string
}