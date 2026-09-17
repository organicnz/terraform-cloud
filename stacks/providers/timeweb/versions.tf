terraform {
  required_version = ">= 1.4.4"

  required_providers {
    twc = {
      source  = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
      version = "~> 1.4.4"
    }
  }
}