variable "project" {
  type = string
}

variable "network" {
  type = string
}

variable "region" {
  type = string
}

variable "zones" {
  type = list(string)
}

variable "cidr_range" {
}

variable "machine_type" {
  type = string
}

variable "target_size" {
  type    = number
  default = 3
}

variable "token" {
  type = string
}

variable "master_address" {
  type = string
}

variable "sdtd-k3s-workers-service-account" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_key_file" {
  type = string
}