
variable "subnet_service_endpoints" {
  description = "List of Service Endpoints"
  type        = list(string)
  default     = ["Microsoft.ContainerRegistry"]
}
