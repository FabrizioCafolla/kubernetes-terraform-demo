variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "microservice_name" {
  description = "Microservice name"
  type        = string
  default     = "api"
}

variable "microservice_replicas" {
  description = "Microservice replicas"
  type        = number
  default     = 1
}

variable "microservice_version" {
  description = "Microservice version"
  type        = string
}

variable "port" {
  description = "Local port"
  type        = number
  default     = 80
}
