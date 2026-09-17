data "twc_ssh_keys" "your-key" {
  name = "your-key"
}

data "twc_configurator" "configurator" {
  location  = "ru-1"
  disk_type = "nvme"
}

data "twc_os" "os" {
  name    = "ubuntu"
  version = "22.04"
}

resource "twc_server" "my-timeweb-server" {
  name         = var.instance_name
  os_id        = data.twc_os.os.id
  ssh_keys_ids = [data.twc_ssh_keys.your-key.id]

  configuration {
    configurator_id = data.twc_configurator.configurator.id
    disk            = 40960
    cpu             = 2
    ram             = 1024 * 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
