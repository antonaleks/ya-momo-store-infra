terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    region     = "ru-central1-a"
    bucket     = "s3-terraform-state"
    key        = "terraform/managed_kuber.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
