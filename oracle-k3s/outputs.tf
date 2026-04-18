output "public_ip" {
  description = "Public IP address of the k3s node"
  value       = module.compute.public_ip
}

output "kubeconfig_path" {
  description = "Local path where kubeconfig was saved after provisioning"
  value       = "${path.root}/kubeconfig"
}

output "kubectl_command" {
  description = "Command to verify cluster access"
  value       = "KUBECONFIG=${path.root}/kubeconfig kubectl get nodes"
}
