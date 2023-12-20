terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.44.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
  # After you run the terraform apply command
  # the first time, uncomment the following code
  # to start storing tfstate remotly
  #
  # backend "s3" {
  #   bucket  = var.s3_bucket_name
  #   region  = "your_aws_region"
  #   profile = "your_aws_profile"
  #   key     = "hcloud-tf"
  # }
}

# Provider configuration
variable "hcloud_token" {
  type        = string
  description = "hetzner cloud API token"
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "aws" {
  region  = "eu-central-1"
  profile = "codebehind"
}

variable "s3_bucket_name" {
  type        = string
  description = "name of the s3 bucket which will hold the terraform's state"
}

# S3 bucket which will hold the state
resource "aws_s3_bucket" "tfstate" {
  bucket = var.s3_bucket_name
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SSH keypair
resource "hcloud_ssh_key" "internal" {
  name       = "kubekey"
  public_key = file("./kubekey.pub")
}

# Network
variable "network_cidr" {
  type        = string
  description = "hetzner cloud network CIDR block"
}

resource "hcloud_network" "main" {
  name     = "net"
  ip_range = var.network_cidr
}

variable "subnets" {
  type        = list(string)
  description = "subnet cidr blocks"
}

resource "hcloud_network_subnet" "subnets" {
  count        = length(var.subnets)
  network_id   = hcloud_network.main.id
  ip_range     = var.subnets[count.index]
  type         = "cloud"
  network_zone = "eu-central"
  depends_on   = [hcloud_network.main]
}

# Kubernetes nodes
variable "controlplanes" {
  type = map(
    object(
      {
        ip_addr     = string
        server_type = string
        image       = string
        location    = string
        protection  = bool
      }
    )
  )
}

resource "hcloud_server" "controlplane" {
  for_each          = var.controlplanes
  name              = each.key
  image             = each.value.image
  location          = each.value.location
  server_type       = each.value.server_type
  delete_protection = each.value.protection
  network {
    network_id = hcloud_network.main.id
    ip         = each.value.ip_addr
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [
    hcloud_ssh_key.internal.id
  ]
  firewall_ids = [
    hcloud_firewall.allow_internal.id,
    hcloud_firewall.allow_ssh.id
  ]
  depends_on = [
    hcloud_ssh_key.internal,
    hcloud_network.main,
    hcloud_firewall.allow_internal,
    hcloud_network_subnet.subnets
  ]
}

variable "nodes" {
  type = map(
    object(
      {
        ip_addr     = string
        server_type = string
        image       = string
        location    = string
        protection  = bool
      }
    )
  )
}

resource "hcloud_server" "node" {
  for_each          = var.nodes
  name              = each.key
  image             = each.value.image
  location          = each.value.location
  server_type       = each.value.server_type
  delete_protection = each.value.protection
  network {
    network_id = hcloud_network.main.id
    ip         = each.value.ip_addr
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [
    hcloud_ssh_key.internal.id
  ]
  firewall_ids = [
    hcloud_firewall.allow_internal.id,
    hcloud_firewall.allow_ssh.id
  ]
  depends_on = [
    hcloud_ssh_key.internal,
    hcloud_network.main,
    hcloud_firewall.allow_internal,
    hcloud_network_subnet.subnets
  ]
}

variable "loadbalancers" {
  type = map(
    object(
      {
        ip_addr     = string
        server_type = string
        image       = string
        location    = string
        protection  = bool
      }
    )
  )
}

resource "hcloud_server" "loadbalancer" {
  for_each          = var.loadbalancers
  name              = each.key
  image             = each.value.image
  location          = each.value.location
  server_type       = each.value.server_type
  delete_protection = each.value.protection
  network {
    network_id = hcloud_network.main.id
    ip         = each.value.ip_addr
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [
    hcloud_ssh_key.internal.id
  ]
  firewall_ids = [
    hcloud_firewall.allow_internal.id,
    hcloud_firewall.allow_ssh.id,
    hcloud_firewall.allow_http.id,
  ]
  depends_on = [
    hcloud_ssh_key.internal,
    hcloud_network.main,
    hcloud_firewall.allow_http,
    hcloud_network_subnet.subnets
  ]
}

# Firewalls
resource "hcloud_firewall" "allow_ssh" {
  name = "allow-ssh"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
}

resource "hcloud_firewall" "allow_http" {
  name = "allow-http"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall" "allow_internal" {
  name = "allow-internal"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "any"
    source_ips = [
      hcloud_network.main.ip_range
    ]
  }
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      hcloud_network.main.ip_range
    ]
  }
  depends_on = [hcloud_network.main]
}
