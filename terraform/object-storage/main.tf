resource "yandex_iam_service_account" "sa" {
  name = var.sa_name
}

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  count = length(var.bucket_name)
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "terraform-object-storage" {
  count = length(var.bucket_name)
  access_key = yandex_iam_service_account_static_access_key.sa-static-key[count.index].access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key[count.index].secret_key
  bucket     = var.bucket_name[count.index]
}

output "bucket" {
  value = {
    "access_key": yandex_storage_bucket.terraform-object-storage[0].access_key,
    "bucket_name": yandex_storage_bucket.terraform-object-storage[0].bucket,
    "secret_key": yandex_storage_bucket.terraform-object-storage[0].secret_key,
  }
  sensitive = true
}
