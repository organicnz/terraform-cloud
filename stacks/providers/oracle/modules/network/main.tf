# Network Module - Main Configuration

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
}

# VCN
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  display_name   = "${local.resource_prefix}-vcn"
  cidr_blocks    = [var.vcn_cidr_block]
  dns_label      = replace(var.project_name, "-", "")

  freeform_tags = merge(
    var.tags,
    {
      Name = "${local.resource_prefix}-vcn"
    }
  )
}

# Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.resource_prefix}-igw"
  enabled        = true

  freeform_tags = var.tags
}

# Route Table
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.resource_prefix}-public-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Default route to internet"
  }

  freeform_tags = var.tags
}

# Network Security Group (better than security lists)
resource "oci_core_network_security_group" "remnawave" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.resource_prefix}-nsg"

  freeform_tags = var.tags
}

# NSG Rules - SSH
resource "oci_core_network_security_group_security_rule" "ssh_ingress" {
  network_security_group_id = oci_core_network_security_group.remnawave.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  description               = "Allow SSH from specified CIDRs"

  source      = var.allowed_ssh_cidrs[0]
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# NSG Rules - HTTP
resource "oci_core_network_security_group_security_rule" "http_ingress" {
  network_security_group_id = oci_core_network_security_group.remnawave.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  description               = "Allow HTTP"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

# NSG Rules - HTTPS
resource "oci_core_network_security_group_security_rule" "https_ingress" {
  network_security_group_id = oci_core_network_security_group.remnawave.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  description               = "Allow HTTPS"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# NSG Rules - Remnawave API
resource "oci_core_network_security_group_security_rule" "remnawave_api_ingress" {
  network_security_group_id = oci_core_network_security_group.remnawave.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  description               = "Allow Remnawave Node API"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 2222
      max = 2222
    }
  }
}

# NSG Rules - ICMP
resource "oci_core_network_security_group_security_rule" "icmp_ingress" {
  network_security_group_id = oci_core_network_security_group.remnawave.id
  direction                 = "INGRESS"
  protocol                  = "1" # ICMP
  description               = "Allow ICMP (ping)"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false
}

# NSG Rules - Egress (allow all)
resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.remnawave.id
  direction                 = "EGRESS"
  protocol                  = "all"
  description               = "Allow all outbound"

  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  stateless        = false
}

# Public Subnet
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.subnet_cidr_block
  display_name               = "${local.resource_prefix}-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false

  freeform_tags = var.tags
}
