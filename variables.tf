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
  defualt     = ""
}