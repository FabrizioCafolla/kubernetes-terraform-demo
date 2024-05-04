output "namespace_name" {
  description = "Namespace name"
  value       = resource.kubernetes_namespace.namespace.metadata[0].name
}
