output "public_ip" {
   value = ["${google_compute_instance.jenkins-master-1.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
