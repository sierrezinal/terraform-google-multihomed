variable "region" {
  default = "us-west1"
}

variable "region_zone" {
  default = "us-west1-a"
}

variable "org_id" {
  description = "The ID of the Google Cloud Organization."
  default     = 111111111111
}

variable "billing_account_id" {
  description = "The ID of the associated billing account (optional)."
  default     = "000000-000000-000000"
}

variable "credentials_file_path" {
  description = "Location of the credentials to use."
  default     = "~/.gcloud/auser-admin1.json"
}

variable "owner" {
  default = "auser@example.com"
}