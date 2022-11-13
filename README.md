# Self-hosted Kubernetes for AWS

## About

This terraform module provides for setting up a self-hosted Kubernetes cluster in the AWS cloud.

It creates the subnet in provided VPC, a security group for cluster and cluster nodes. Each node setting up with init
scripts (aka user_data).

## How to

Connect AWS in your terraform file (example):

```terraform
provider "aws" {
  region = "eu-north-1"
}

terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "k8s-aws.tfstate"
    region = "eu-north-1"
  }
}
```

You need to pass `aws_vpc.id` to the module variable. You can use the default and create your own:

```terraform
resource "aws_vpc" "main" {
  cidr_block           = "10.240.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = {
    Name = "gelugu"
  }
}
```

Connect and setup module with variables:

```terraform
module "kubernetes" {
  # ssh
  source = "git@github.com:gelugu/terraform-aws-kubernetes.git?ref=main"

  region = "eu-north-1"

  vpc_id        = aws_vpc.main.id 
  subnet_netnum = 1

  cluster_name = "gelugu"

  ssh_public_key = "your@ssh.key"

  master_instance_type = "t3.small"
  master_count         = 2
  worker_instance_type = "t3.small"
  worker_count         = 3

  instance_ami = "ami-0efda064d1b5e46a5" # Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2022-09-12
}
```

Remember, to enable outputs from the module you need to specify a separate output namespace:

```terraform
output "kubernetes_output" {
  value = module.kubernetes
}
```

## variables

* region - AWS region for the cluster (obviously it must be the same region with VPC)
* vpc_id - aws_vpc.id for subnet, gateway and security groups
* [subnet_netnum](https://developer.hashicorp.com/terraform/language/functions/cidrsubnet)
* cluster_name - Name of the cluster.
* ssh_public_key - public key for connection to nodes.
* master_instance_type - AWS instance type for master nodes.
* worker_instance_type - AWS instance type for worker nodes.
* master_count - number of master instances.
* worker_count - number of worker instances.
* instance_ami - AWS image id for all instances.

## Outputs

* join_command - command to join nodes to the main control-plane.

## Issues

* deliver certs between control-plane nodes
* automatic join nodes
* polish init scripts
* merge init scripts
* split subnets
* add EIP and ELB
* configure security groups
