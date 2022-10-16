variable "project" {
  type = string
}

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
}

variable "machine_type" {
  type = string
}

variable "target_size" {
  type = number
  default = 3
}

variable "service_account" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_key_file" {
  type = string
}