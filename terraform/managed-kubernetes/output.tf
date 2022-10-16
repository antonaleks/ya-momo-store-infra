output "k8s_nodes" {
  value = [
    flatten(yandex_kubernetes_node_group.k8s_node_group[*].instance_template)
  ]
}
