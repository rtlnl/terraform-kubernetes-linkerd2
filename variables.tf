variable "automount_service_account_token" {
  type        = bool
  description = "Enable automatic mounting of the service account token"
  default     = true
}

variable "high_availability" {
    type = bool
    description = "Enable high availability"
    # default = false UNCOMMENT THIS AND SET TO TRUE FOR PROD
}
