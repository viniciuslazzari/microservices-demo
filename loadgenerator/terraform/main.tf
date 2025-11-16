provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "loadgenerator" {
  name         = "loadgenerator"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${var.public_key}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io git
    systemctl enable docker
    systemctl start docker
  EOT

  tags = ["http-server"]
}

