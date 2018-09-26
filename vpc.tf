resource "random_pet" "network" {
  keepers = {
    network_seed = "${var.network}"
  }
}

resource "google_compute_network" "heretic" {
  name                    = "network-${random_pet.network.id}"
  project                 = "${google_project.proj.project_id}"
  auto_create_subnetworks = "false"
  depends_on              = ["google_project_services.services1"]
}

resource "google_compute_subnetwork" "subnetwork1" {
  name          = "subnet1"
  ip_cidr_range = "10.5.0.0/20"
  project       = "${google_project.proj.project_id}"
  region        = "${var.region}"
  network       = "${google_compute_network.heretic.self_link}"
  depends_on    = ["google_compute_network.heretic"]
}

resource "google_compute_firewall" "firewall_heretic_ingress1" {
  name    = "whitelist-ssh"
  network = "${google_compute_network.heretic.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  project = "${google_project.proj.project_id}"
}

resource "google_compute_firewall" "firewall_heretic_ingress2" {
  name    = "whitelist-icmp"
  network = "${google_compute_network.heretic.self_link}"

  allow {
    protocol = "icmp"
  }

  project = "${google_project.proj.project_id}"
}

output "subnetwork1.gateway" {
  value = "${google_compute_subnetwork.subnetwork1.gateway_address}"
}
