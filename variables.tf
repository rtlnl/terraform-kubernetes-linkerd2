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

variable "module_depends_on" {
  type        = any
  description = "Variable to pass dependancy on external module" # https://discuss.hashicorp.com/t/tips-howto-implement-module-depends-on-emulation/2305/2
  default     = null
}