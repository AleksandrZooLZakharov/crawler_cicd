output "gitlab_ip" {
  value = "${google_compute_instance.gitlab-ci.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "mongo_ip" {
  value = "${google_compute_instance.mongo.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "mongo_internal_ip" {
  value = "${google_compute_instance.mongo.network_interface.0.network_ip}"
}

output "rabbitmq_ip" {
  value = "${google_compute_instance.rabbitmq.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "rabbitmq_internal_ip" {
  value = "${google_compute_instance.rabbitmq.network_interface.0.network_ip}"
}