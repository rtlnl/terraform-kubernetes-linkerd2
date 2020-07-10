variable "automount_service_account_token" {
  type        = bool
  description = "Enable automatic mounting of the service account token"
}

variable "high_availability" {
    type = bool
    description = "Enable high availability"
}
