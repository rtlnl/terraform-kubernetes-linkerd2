resource "kubernetes_cluster_role" "linkerd_linkerd_tap" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name = "linkerd-linkerd-tap"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = [""]
    resources  = ["pods", "services", "replicationcontrollers", "namespaces", "nodes"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "apps"]
    resources  = ["daemonsets", "deployments", "replicasets", "statefulsets"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "batch"]
    resources  = ["cronjobs", "jobs"]
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_tap_admin" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name = "linkerd-linkerd-tap-admin"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
  }
  rule {
    verbs      = ["watch"]
    api_groups = ["tap.linkerd.io"]
    resources  = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_tap" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name = "linkerd-linkerd-tap"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_tap_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-tap"
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_tap_auth_delegator" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name = "linkerd-linkerd-tap-auth-delegator"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_tap_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
}

resource "kubernetes_service_account" "linkerd_tap" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name      = local.linkerd_tap_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
  }
}

resource "kubernetes_role_binding" "linkerd_linkerd_tap_auth_reader" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name      = "linkerd-linkerd-tap-auth-reader"
    namespace = "kube-system"
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_tap_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }
}

resource "kubernetes_api_service" "v1alpha1_tap_linkerd_io" {
  depends_on = [
    kubernetes_namespace.linkerd[0],
    kubernetes_cluster_role.linkerd_linkerd_tap,
    kubernetes_cluster_role.linkerd_linkerd_tap_admin,
    kubernetes_cluster_role_binding.linkerd_linkerd_tap,
    kubernetes_cluster_role_binding.linkerd_linkerd_tap_auth_delegator,
    kubernetes_service_account.linkerd_tap,
    kubernetes_role_binding.linkerd_linkerd_tap_auth_reader
  ]

  metadata {
    name = "v1alpha1.tap.linkerd.io"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
  }
  spec {
    service {
      namespace = local.linkerd_namespace
      name      = local.linkerd_tap_name
    }
    group                  = "tap.linkerd.io"
    version                = "v1alpha1"
    ca_bundle              = file("${path.module}/certs/ca_bundle")
    group_priority_minimum = 1000
    version_priority       = 100
  }
}

resource "kubernetes_service" "linkerd_tap" {
  depends_on = [
    kubernetes_namespace.linkerd[0],
    kubernetes_cluster_role.linkerd_linkerd_tap,
    kubernetes_cluster_role.linkerd_linkerd_tap_admin,
    kubernetes_cluster_role_binding.linkerd_linkerd_tap,
    kubernetes_cluster_role_binding.linkerd_linkerd_tap_auth_delegator,
    kubernetes_service_account.linkerd_tap,
    kubernetes_role_binding.linkerd_linkerd_tap_auth_reader,
    kubernetes_api_service.v1alpha1_tap_linkerd_io
  ]

  metadata {
    name      = local.linkerd_tap_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    })
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "grpc"
      port        = 8088
      target_port = "8088"
    }
    port {
      name        = "apiserver"
      port        = 443
      target_port = "apiserver"
    }
    selector = {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
    }
  }
}

resource "kubernetes_deployment" "linkerd_tap" {
  depends_on = [
    kubernetes_namespace.linkerd[0],
    kubernetes_config_map.linkerd_config,
    kubernetes_config_map.linkerd_config_addons,
    kubernetes_secret.linkerd_tap_tls,
    kubernetes_cluster_role.linkerd_linkerd_tap,
    kubernetes_cluster_role.linkerd_linkerd_tap_admin,
    kubernetes_cluster_role_binding.linkerd_linkerd_tap,
    kubernetes_cluster_role_binding.linkerd_linkerd_tap_auth_delegator,
    kubernetes_service_account.linkerd_tap,
    kubernetes_role_binding.linkerd_linkerd_tap_auth_reader,
    kubernetes_api_service.v1alpha1_tap_linkerd_io,
    kubernetes_deployment.linkerd_identity
  ]

  metadata {
    name      = local.linkerd_tap_name
    namespace = local.linkerd_namespace
    labels    = merge(
      local.linkerd_label_control_plane_ns,
      local.linkerd_label_partof_version,
      {
        "app.kubernetes.io/name"             = local.linkerd_component_tap_name,
        "linkerd.io/control-plane-component" = local.linkerd_component_tap_name
      }
    )
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    replicas = local.controlplane_replicas
    selector {
      match_labels = merge(local.linkerd_label_control_plane_ns, {
        "linkerd.io/control-plane-component" = local.linkerd_component_tap_name,
        "linkerd.io/proxy-deployment"        = local.linkerd_tap_name
      })
    }
    template {
      metadata {
        labels = merge(
          local.linkerd_label_control_plane_ns,
          local.linkerd_label_workload_ns,
          {
            "linkerd.io/control-plane-component" = local.linkerd_component_tap_name,
            "linkerd.io/proxy-deployment"        = local.linkerd_tap_name
          }
        )
        annotations = local.linkerd_annotations_for_deployment
      }
      spec {
        volume {
          name = "config"
          config_map {
            name = "linkerd-config"
          }
        }
        volume {
          name = "linkerd-identity-end-entity"
          empty_dir {
            medium = "Memory"
          }
        }
        volume {
          name = "tls"
          secret {
            secret_name = "linkerd-tap-tls"
          }
        }
        automount_service_account_token = var.automount_service_account_token
        init_container {
          name  = local.linkerd_init_container_name
          image =  local.linkerd_deployment_proxy_init_image
          args = [
            "--incoming-proxy-port",
            "${local.linkerd_deployment_incoming_proxy_port}",
            "--outgoing-proxy-port",
            "${local.linkerd_deployment_outgoing_proxy_port}",
            "--proxy-uid",
            "${local.linkerd_deployment_proxy_uid}",
            "--inbound-ports-to-ignore",
            "${local.linkerd_deployment_proxy_control_port},${local.linkerd_deployment_admin_port}",
            "--outbound-ports-to-ignore",
            "${local.linkerd_deployment_outbound_port}"
          ]
          resources {
            limits {
              cpu    = "100m"
              memory = "50Mi"
            }
            requests {
              cpu    = "10m"
              memory = "10Mi"
            }
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            capabilities {
              add = ["NET_ADMIN", "NET_RAW"]
            }
            read_only_root_filesystem = true
          }
        }
        container {
          name  = local.linkerd_component_tap_name
          image =  local.linkerd_deployment_controller_image
          args  = [local.linkerd_component_tap_name, "-controller-namespace=${local.linkerd_namespace}", "-log-level=${local.linkerd_container_log_level}"]
          port {
            name           = "grpc"
            container_port = 8088
          }
          port {
            name           = "apiserver"
            container_port = 8089
          }
          port {
            name           = "admin-http"
            container_port = 9998
          }
          resources {
            limits {
              cpu    = "1"
              memory = "250Mi"
            }
            requests {
              memory = "50Mi"
              cpu    = "100m"
            }
          }
          volume_mount {
            name       = "tls"
            read_only  = true
            mount_path = "/var/run/linkerd/tls"
          }
          volume_mount {
            name       = "config"
            mount_path = "/var/run/linkerd/config"
          }
          liveness_probe {
            http_get {
              path = "/ping"
              port = "9998"
            }
            initial_delay_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "9998"
            }
            failure_threshold = 7
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user = local.linkerd_deployment_security_context_user
          }
        }
        container {
          name  = local.linkerd_proxy_container_name
          image = local.linkerd_deployment_proxy_image
          port {
            name           = local.linkerd_deployment_proxy_port_name
            container_port = local.linkerd_deployment_incoming_proxy_port
          }
          port {
            name           = local.linkerd_deployment_admin_port_name
            container_port = local.linkerd_deployment_admin_port
          }
          env {
            name = "_pod_ns"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name = "_pod_sa"
            value_from {
              field_ref {
                field_path = "spec.serviceAccountName"
              }
            }
          }
          dynamic "env" {
            for_each = local.linkerd_deployment_container_env_variables

            content {
              name = env.value["name"]
              value = env.value["value"]
            }
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_SVC_ADDR"
            value = local.linkerd_proxy_destination_svc_addr
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_SVC_ADDR"
            value = local.linkerd_proxy_identity_svc_addr
          }
          resources {
            limits {
              cpu    = "1"
              memory = "250Mi"
            }
            requests {
              cpu    = "100m"
              memory = "20Mi"
            }
          }
          volume_mount {
            name       = "linkerd-identity-end-entity"
            mount_path = "/var/run/linkerd/identity/end-entity"
          }
          liveness_probe {
            http_get {
              path = "/live"
              port = local.linkerd_deployment_admin_port
            }
            initial_delay_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = local.linkerd_deployment_admin_port
            }
            initial_delay_seconds = 2
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user               = local.linkerd_deployment_proxy_uid
            read_only_root_filesystem = true
          }
        }
        node_selector        = { "beta.kubernetes.io/os" = "linux" }
        service_account_name = local.linkerd_tap_name
        dynamic "affinity" {
          for_each = var.high_availability == true ? [map("ha", true)] : []

          content {
            pod_anti_affinity {
                required_during_scheduling_ignored_during_execution {
                    label_selector {
                    match_expressions {
                        key      = "linkerd.io/control-plane-component"
                        operator = "In"
                        values   = [local.linkerd_component_tap_name]
                    }
                    }
                    topology_key = "kubernetes.io/hostname"
                }
                preferred_during_scheduling_ignored_during_execution {
                    weight = 100
                    pod_affinity_term {
                    label_selector {
                        match_expressions {
                        key      = "linkerd.io/control-plane-component"
                        operator = "In"
                        values   = [local.linkerd_component_tap_name]
                        }
                    }
                    topology_key = "failure-domain.beta.kubernetes.io/zone"
                    }
                }
            }
          }
        }
      }
    }
    strategy {
      rolling_update {
        max_unavailable = "1"
      }
    }
  }
}
