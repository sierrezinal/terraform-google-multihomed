provider "google" {
  region      = "${var.region}"
  credentials = "${file("${var.credentials_file_path}")}"
  version     = "~> 1.16"
}

resource "google_project" "proj" {
  name            = "Two Network Interfaces"
  project_id      = "tf-2interfaces"
  billing_account = "${var.billing_account_id}"
  org_id          = "${var.org_id}"
}

resource "google_project_services" "services1" {
  project = "${google_project.proj.project_id}"

  services = [
    "compute.googleapis.com",
    "oslogin.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_iam_binding" "iam1" {
  project = "${google_project.proj.project_id}"
  role    = "roles/editor"

  members = [
    "serviceAccount:${google_project.proj.number}-compute@developer.gserviceaccount.com",
    "serviceAccount:${google_project.proj.number}@cloudservices.gserviceaccount.com",
    "user:${var.owner}",
  ]

  depends_on = ["google_project_services.services1"]
}

output "project_id" {
  value = "${google_project.proj.project_id}"
}

output "project_number" {
  value = "${google_project.proj.number}"
}
