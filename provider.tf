# Specify the provider (GCP, AWS, Azure)
provider "google" {
credentials = "${file("ilawyerlive.json")}"
project = "ilawyer-live"
region = "us-central1"
}
