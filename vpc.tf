resource "google_compute_network" "galileo" {
  name                    = "heretic"
  auto_create_subnetworks = "false"
  project                 = "${google_project.proj.project_id}"
  depends_on              = ["google_project_services.services1"]
}

resource "google_compute_subnetwork" "subnetwork1" {
  name          = "subnet1"
  ip_cidr_range = "10.5.0.0/20"
  region        = "${var.region}"
  network       = "${google_compute_network.galileo.self_link}"
}

resource "google_compute_firewall" "firewall_heretic" {
  name    = "allow-ssh-and-icmp"
  network = "${google_compute_network.galileo.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  project = "${google_project.proj.project_id}"
}

output "subnetwork1.gateway" {
  value = "${google_compute_subnetwork.subnetwork1.gateway_address}"
}
