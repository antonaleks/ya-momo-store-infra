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
  description = "IAM- или OAuth токен"
  type        = string
  sensitive   = true
}

variable "k8s_sa_name" {
  description = "имя сервисного аккаунта"
  type        = string
  default     = "k8s-sa-service"
}

variable "k8s_version" {
  description = "версия kubernetes"
  type        = string
  default     = "1.22"
}

variable "k8s_node_vars" {
  description = "Конфигурация групп узлов"
  type        = list(map(string))
  default     = [
    {
      type        = "staging",
      ram         = "4",
      cpu         = "2",
      platform_id = "standard-v1",
      size = "30"
    },
    {
      type        = "production",
      ram         = "4",
      cpu         = "2",
      platform_id = "standard-v1",
      size = "30"
    },
    {
      type        = "infra",
      ram         = "4",
      cpu         = "2",
      platform_id = "standard-v1",
      size = "30"
    }
  ]
}
