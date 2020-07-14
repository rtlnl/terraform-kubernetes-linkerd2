resource "kubernetes_cluster_role" "linkerd_destination" {
  metadata {
    name = "linkerd-linkerd-destination"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = "destination"
    })
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["apps"]
    resources  = ["replicasets"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["batch"]
    resources  = ["jobs"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = [""]
    resources  = ["pods", "endpoints", "services"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["linkerd.io"]
    resources  = ["serviceprofiles"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["split.smi-spec.io"]
    resources  = ["trafficsplits"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_destination" {
  metadata {
    name = "linkerd-linkerd-destination"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = "destination"
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-destination"
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-destination"
  }
}

resource "kubernetes_service_account" "linkerd_destination" {
  metadata {
    name      = "linkerd-destination"
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = "destination"
    })
  }
}

resource "kubernetes_service" "linkerd_dst" {
  depends_on = [
    kubernetes_cluster_role.linkerd_destination,
    kubernetes_cluster_role_binding.linkerd_destination,
    kubernetes_service_account.linkerd_destination
  ]

  metadata {
    name      = "linkerd-dst"
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = "destination"
    })
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "grpc"
      port        = 8086
      target_port = "8086"
    }
    selector = {
      "linkerd.io/control-plane-component" = "destination"
    }
  }
}

resource "kubernetes_deployment" "linkerd_destination" {
  depends_on = [
    kubernetes_cluster_role.linkerd_destination,
    kubernetes_cluster_role_binding.linkerd_destination,
    kubernetes_service_account.linkerd_destination
  ]

  metadata {
    name      = "linkerd-destination"
    namespace = local.linkerd_namespace
    labels    = merge(
      local.linkerd_label_control_plane_ns,
      local.linkerd_label_partof_version,
      {
        "app.kubernetes.io/name"             = "destination",
        "linkerd.io/control-plane-component" = "destination"
      }
    )
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    replicas = 1
    selector {
      match_labels = merge(local.linkerd_label_control_plane_ns, {
        "linkerd.io/control-plane-component" = "destination",
        "linkerd.io/proxy-deployment"        = "linkerd-destination"
      })
    }
    template {
      metadata {
        labels = merge(
          local.linkerd_label_control_plane_ns,
          local.linkerd_label_workload_ns,
          {
            "linkerd.io/control-plane-component" = "destination",
            "linkerd.io/proxy-deployment"        = "linkerd-destination"
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
        automount_service_account_token = var.automount_service_account_token
        init_container {
          name  = "linkerd-init"
          image =  local.linkerd_deployment_proxy_init_image
          args = [
            "--incoming-proxy-port",
            "${local.linkerd_deployment_incoming_proxy_port}",
            "--outgoing-proxy-port",
            "${local.linkerd_deployment_outgoing_proxy_port}",
            "--proxy-uid",
            "${local.linkerd_deployment_proxy_uid}",
            "--inbound-ports-to-ignore",
            "${local.linkerd_deployment_proxy_control_port},4191",
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
          name  = "destination"
          image =  local.linkerd_deployment_controller_image
          args = [
            "destination",
            "-addr=:8086",
            "-controller-namespace=linkerd",
            "-enable-h2-upgrade=true",
            "-log-level=info"
          ]
          port {
            name           = "grpc"
            container_port = 8086
          }
          port {
            name           = "admin-http"
            container_port = 9996
          }
          resources {
            limits {
              cpu    = "1"
              memory = "250Mi"
            }
            requests {
              cpu    = "100m"
              memory = "50Mi"
            }
          }
          volume_mount {
            name       = "config"
            mount_path = "/var/run/linkerd/config"
          }
          liveness_probe {
            http_get {
              path = "/ping"
              port = "9996"
            }
            initial_delay_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "9996"
            }
            failure_threshold = 7
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user = 2103
          }
        }
        container {
          name  = "linkerd-proxy"
          image = local.linkerd_deployment_proxy_image
          port {
            name           = "linkerd-proxy"
            container_port = local.linkerd_deployment_incoming_proxy_port
          }
          port {
            name           = "linkerd-admin"
            container_port = local.linkerd_deployment_admin_port
          }
          env {
            name  = "LINKERD2_PROXY_LOG"
            value = "warn,linkerd=info"
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_SVC_ADDR"
            value = "localhost.:8086"
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_GET_NETWORKS"
            value = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
          }
          env {
            name  = "LINKERD2_PROXY_CONTROL_LISTEN_ADDR"
            value = "0.0.0.0:${local.linkerd_deployment_proxy_control_port}"
          }
          env {
            name  = "LINKERD2_PROXY_ADMIN_LISTEN_ADDR"
            value = "0.0.0.0:4191"
          }
          env {
            name  = "LINKERD2_PROXY_OUTBOUND_LISTEN_ADDR"
            value = "127.0.0.1:4140"
          }
          env {
            name  = "LINKERD2_PROXY_INBOUND_LISTEN_ADDR"
            value = "0.0.0.0:4143"
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_GET_SUFFIXES"
            value = "svc.cluster.local."
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_PROFILE_SUFFIXES"
            value = "svc.cluster.local."
          }
          env {
            name  = "LINKERD2_PROXY_INBOUND_ACCEPT_KEEPALIVE"
            value = "10000ms"
          }
          env {
            name  = "LINKERD2_PROXY_OUTBOUND_CONNECT_KEEPALIVE"
            value = "10000ms"
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
            name  = "LINKERD2_PROXY_DESTINATION_CONTEXT"
            value = "ns:$(_pod_ns)"
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_DIR"
            value = "/var/run/linkerd/identity/end-entity"
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_TRUST_ANCHORS"
            value = file("${path.module}/certs/proxy_trust_anchor.pem")
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_TOKEN_FILE"
            value = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_SVC_ADDR"
            value = "linkerd-identity.linkerd.svc.cluster.local:8080"
          }
          env {
            name = "_pod_sa"
            value_from {
              field_ref {
                field_path = "spec.serviceAccountName"
              }
            }
          }
          env {
            name  = "_l5d_ns"
            value = "linkerd"
          }
          env {
            name  = "_l5d_trustdomain"
            value = "cluster.local"
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_LOCAL_NAME"
            value = "$(_pod_sa).$(_pod_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_SVC_NAME"
            value = "linkerd-identity.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_SVC_NAME"
            value = "linkerd-destination.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
          }
          env {
            name  = "LINKERD2_PROXY_TAP_SVC_NAME"
            value = "linkerd-tap.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)"
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
              port = "4191"
            }
            initial_delay_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "4191"
            }
            initial_delay_seconds = 2
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user               = 2102
            read_only_root_filesystem = true
          }
        }
        node_selector        = { "beta.kubernetes.io/os" = "linux" }
        service_account_name = "linkerd-destination"
        dynamic "affinity" {
          for_each = var.high_availability == true ? [map("ha", true)] : []

          content {
            pod_anti_affinity {
                required_during_scheduling_ignored_during_execution {
                    label_selector {
                    match_expressions {
                        key      = "linkerd.io/control-plane-component"
                        operator = "In"
                        values   = ["destination"]
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
                        values   = ["destination"]
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
