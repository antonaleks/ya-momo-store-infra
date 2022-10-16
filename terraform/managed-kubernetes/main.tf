locals {
  folder_id   = var.yc_folder_id
  k8s_version = var.k8s_version
  sa_name     = var.k8s_sa_name
}

resource "yandex_kubernetes_cluster" "k8s-zonal" {
  network_id = yandex_vpc_network.k8s-net.id
  master {
    version = local.k8s_version
    zonal {
      zone      = yandex_vpc_subnet.k8s-subnet.zone
      subnet_id = yandex_vpc_subnet.k8s-subnet.id
    }
    public_ip = true
  }
  service_account_id      = yandex_iam_service_account.k8s-sa-account.id
  node_service_account_id = yandex_iam_service_account.k8s-sa-account.id
  depends_on              = [
    yandex_resourcemanager_folder_iam_binding.k8s-editor,
    yandex_resourcemanager_folder_iam_binding.k8s-puller,
  ]
}

resource "yandex_kubernetes_node_group" "k8s_node_group" {
  cluster_id  = "${yandex_kubernetes_cluster.k8s-zonal.id}"
  name        = "k8s-node-${var.k8s_node_vars[count.index].type}"
  count       = length(var.k8s_node_vars)
  description = "node group for k8s cluster"
  version     = var.k8s_version

  labels = {
    "environment.type" = var.k8s_node_vars[count.index].type
  }

  node_labels = {
    "environment.type" = var.k8s_node_vars[count.index].type
  }

  instance_template {
    platform_id = var.k8s_node_vars[count.index].platform_id

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.k8s-subnet.id}"]
    }

    resources {
      memory = var.k8s_node_vars[count.index].ram
      cores  = var.k8s_node_vars[count.index].cpu
    }

    boot_disk {
      type = "network-hdd"
      size = var.k8s_node_vars[count.index].size
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 3
      initial = 1
    }
  }

  allocation_policy {
    location {
      zone = var.yc_region
    }
  }
}

resource "yandex_vpc_network" "k8s-net" { name = "k8s-net" }

resource "yandex_vpc_subnet" "k8s-subnet" {
  v4_cidr_blocks = ["10.1.0.0/16"]
  zone           = var.yc_region
  network_id     = yandex_vpc_network.k8s-net.id
}

resource "yandex_iam_service_account" "k8s-sa-account" {
  name        = local.sa_name
  description = "K8S zonal service account"
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s-editor" {
  # Сервисному аккаунту назначается роль "admin".
  folder_id = local.folder_id
  role      = "editor"
  members   = [
    "serviceAccount:${yandex_iam_service_account.k8s-sa-account.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s-puller" {
  # Сервисному аккаунту назначается роль "container-registry.images.puller".
  folder_id = local.folder_id
  role      = "container-registry.images.puller"
  members   = [
    "serviceAccount:${yandex_iam_service_account.k8s-sa-account.id}"
  ]
}
