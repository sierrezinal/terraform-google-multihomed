resource "google_compute_instance" "vm" {
  project                   = "${google_project.proj.project_id}"
  name                      = "twonics"
  machine_type              = "f1-micro"
  zone                      = "${var.region_zone}"
  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = ["boot_disk.0.initialize_params.0.image"]
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1604-lts"
    }
  }

  tags = ["multihomed"]

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnetwork1.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
}

output "ip1" {
  value = "${google_compute_instance.vm.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ip2" {
  value = "${google_compute_instance.vm.network_interface.1.access_config.0.assigned_nat_ip}"
}
