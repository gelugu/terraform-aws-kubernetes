variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}
variable "subnet_netnum" {
  type = number
}

variable "ssh_public_key" {
  type = string
}

variable "cluster_name" {
  type = string
}
variable "master_instance_type" {
  type = string
}
variable "master_count" {
  type = number
}
variable "worker_instance_type" {
  type = string
}
variable "worker_count" {
  type = number
}
variable "instance_ami" {
  type = string
}
