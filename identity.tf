resource "kubernetes_cluster_role" "linkerd_identity" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name = "linkerd-linkerd-identity"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_identity_name
    })
  }
  rule {
    verbs      = ["create"]
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
  }
  rule {
    verbs      = ["get"]
    api_groups = ["apps"]
    resources  = ["deployments"]
  }
  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["secrets"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_identity" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name = "linkerd-linkerd-identity"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_identity_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_identity_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-identity"
  }
}

resource "kubernetes_service_account" "linkerd_identity" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name      = local.linkerd_identity_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_identity_name
    })
  }
}

resource "kubernetes_service" "linkerd_identity" {
  depends_on = [
    kubernetes_namespace.linkerd[0],
    kubernetes_cluster_role.linkerd_identity,
    kubernetes_cluster_role_binding.linkerd_identity,
    kubernetes_service_account.linkerd_identity
  ]

  metadata {
    name      = local.linkerd_identity_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_identity_name
    })
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "grpc"
      port        = 8080
      target_port = "8080"
    }
    selector = {
      "linkerd.io/control-plane-component" = local.linkerd_component_identity_name
    }
  }
}

resource "kubernetes_deployment" "linkerd_identity" {

  depends_on = [
    kubernetes_namespace.linkerd[0],
    kubernetes_config_map.linkerd_config,
    kubernetes_config_map.linkerd_config_addons,
    kubernetes_secret.linkerd_identity_issuer,
    kubernetes_cluster_role.linkerd_identity,
    kubernetes_cluster_role_binding.linkerd_identity,
    kubernetes_service_account.linkerd_identity
  ]

  metadata {
    name      = local.linkerd_identity_name
    namespace = local.linkerd_namespace
    labels = merge(
      local.linkerd_label_control_plane_ns,
      local.linkerd_label_partof_version,
      {
        "app.kubernetes.io/name"             = local.linkerd_component_identity_name,
        "linkerd.io/control-plane-component" = local.linkerd_component_identity_name
      }
    )
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    replicas = 1
    selector {
      match_labels = merge(local.linkerd_label_control_plane_ns, {
        "linkerd.io/control-plane-component" = local.linkerd_component_identity_name,
        "linkerd.io/proxy-deployment"        = local.linkerd_identity_name
      })
    }
    template {
      metadata {
        labels = merge(
          local.linkerd_label_control_plane_ns,
          local.linkerd_label_workload_ns,
          {
            "linkerd.io/control-plane-component" = local.linkerd_component_identity_name,
            "linkerd.io/proxy-deployment"        = local.linkerd_identity_name
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
          name = "identity-issuer"
          secret {
            secret_name = "linkerd-identity-issuer"
          }
        }
        volume {
          name = "linkerd-identity-end-entity"
          empty_dir {
            medium = "Memory"
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
          name  = local.linkerd_component_identity_name
          image =  local.linkerd_deployment_controller_image
          args  = [local.linkerd_component_identity_name, "-log-level=${local.linkerd_container_log_level}"]
          port {
            name           = "grpc"
            container_port = 8080
          }
          port {
            name           = "admin-http"
            container_port = 9990
          }
          resources {
            limits {
              cpu    = "1"
              memory = "250Mi"
            }
            requests {
              cpu    = "100m"
              memory = "10Mi"
            }
          }
          volume_mount {
            name       = "config"
            mount_path = "/var/run/linkerd/config"
          }
          volume_mount {
            name       = "identity-issuer"
            mount_path = "/var/run/linkerd/identity/issuer"
          }
          liveness_probe {
            http_get {
              path = "/ping"
              port = "9990"
            }
            initial_delay_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "9990"
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
            value = "localhost.:8080"
          }
          resources {
            limits {
              memory = "250Mi"
              cpu    = "1"
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
        service_account_name = local.linkerd_identity_name
        dynamic "affinity" {
          for_each = var.high_availability == true ? [map("ha", true)] : []

          content {
            pod_anti_affinity {
                required_during_scheduling_ignored_during_execution {
                    label_selector {
                    match_expressions {
                        key      = "linkerd.io/control-plane-component"
                        operator = "In"
                        values   = [local.linkerd_component_identity_name]
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
                        values   = [local.linkerd_component_identity_name]
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
