variable "yc_region" {
  description = "регион"
  type        = string
  default     = "ru-central1-a"
}

variable "yc_folder_id" {
  description = "идентификатор каталога"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "идентификатор облака"
  type        = string
  sensitive   = true
}

variable "yc_token" {
  description = "IAM- или OAuth-токен"
  type        = string
  sensitive   = true
}

variable "sa_name" {
  description = "имя сервисного аккаунта"
  type        = string
  default     = "s3-storage-service"
}

variable "bucket_name" {
  description = "имя бакета"
  type        = list(string)
  default     = ["s3-terraform-state", "s3-momo-store-bucket"]
}
