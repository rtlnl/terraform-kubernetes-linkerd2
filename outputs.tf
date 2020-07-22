// used to create eventual dependencies for other modules that need to install other components
// for example: secrets for ingress authentication
output "namespace_name" {
  value = "${kubernetes_namespace.linkerd[0].metadata.0.name}"
}