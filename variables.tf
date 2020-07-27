variable "create_namespace" {
  type        = bool
  description = "create the namespace resource or not"
  default     = true
}

variable "namespace_name" {
  type        = string
  description = "name of the namespace"
  default     = "linkerd"
}

variable "controller_image" {
  type        = string
  description = "docker image name for the controller"
  default     = "gcr.io/linkerd-io/controller"
}

variable "controller_image_tag" {
  type        = string
  description = "docker image tag for the controller"
  default     = "stable-2.8.1"
}

variable "proxy_init_image" {
  type        = string
  description = "docker image name for the proxy_init"
  default     = "gcr.io/linkerd-io/proxy-init"
}

variable "proxy_init_image_tag" {
  type        = string
  description = "docker image tag for the proxy_init"
  default     = "v1.3.3"
}

variable "proxy_image" {
  type        = string
  description = "docker image name for the proxy"
  default     = "gcr.io/linkerd-io/proxy"
}

variable "proxy_image_tag" {
  type        = string
  description = "docker image tag for the proxy"
  default     = "stable-2.8.1"
}

variable "container_log_level" {
  type        = string
  description = "container log level"
  default     = "info"
}

variable "trust_domain" {
  type        = string
  description = "trust domain for TLS certificates"
  default     = "cluster.local"
}

variable "automount_service_account_token" {
  type        = bool
  description = "Enable automatic mounting of the service account token"
  default     = true
}

variable "high_availability" {
  type        = bool
  description = "Enable high availability"
  default     = false
}

variable "controlplane_ha_replicas" {
  type        = number
  description = "amount of replicas for the controlplane components when High Availability is enabled"
  default     = 3
}

variable "proxy_injector_pem" {
  type        = string
  description = "custom proxy injector pem file. See example file in certs folder on how to pass it as string"
  default     = ""
}

variable "sp_validator_pem" {
  type        = string
  description = "custom sp validator pem file. See example file in certs folder on how to pass it as string"
  default     = ""
}

variable "external_identity_issuer" {
  type        = bool
  description = "Use true in Production! If left to false, it will use the certificates coming with this module. For more information: https://linkerd.io/2/tasks/automatically-rotating-control-plane-tls-credentials/"
  default     = false
}

variable "trust_anchors_pem_value" {
  type        = string
  description = "PEM value used as trust anchors"
  default     = ""
}

variable "web_replicas" {
  type        = number
  description = "number of replicas for web component"
  default     = 1
}

variable "enable_web_ingress" {
  type        = bool
  description = "enable the ingress object for the web component"
  default     = false
}

variable "web_ingress_annotations" {
  type        = map(string)
  description = "eventual ingress annotations for the ingress-controller"
  default     = {}
}

variable "web_ingress_host" {
  type        = string
  description = "host name for the web component"
  default     = ""
}

variable "grafana_replicas" {
  type        = number
  description = "number of replicas for grafana component"
  default     = 1
}

variable "prometheus_replicas" {
  type        = number
  description = "number of replicas for prometheus component"
  default     = 1
}

variable "module_depends_on" {
  type        = any
  description = "Variable to pass dependancy on external module" # https://discuss.hashicorp.com/t/tips-howto-implement-module-depends-on-emulation/2305/2
  default     = null
}
