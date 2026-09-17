# Data Sources

# Availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_id
}

# Current region
data "oci_identity_regions" "current" {
  filter {
    name   = "name"
    values = [var.region]
  }
}

# Tenancy information
data "oci_identity_tenancy" "current" {
  tenancy_id = var.tenancy_ocid
}
