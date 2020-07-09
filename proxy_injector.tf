resource "kubernetes_cluster_role" "linkerd_proxy_injector" {
  metadata {
    name = "linkerd-linkerd-proxy-injector"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = [""]
    resources  = ["namespaces", "replicationcontrollers"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["pods"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "batch"]
    resources  = ["cronjobs", "jobs"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_proxy_injector" {
  metadata {
    name = "linkerd-linkerd-proxy-injector"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-proxy-injector"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-proxy-injector"
  }
}

resource "kubernetes_service_account" "linkerd_proxy_injector" {
  metadata {
    name      = "linkerd-proxy-injector"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_service" "linkerd_proxy_injector" {
  depends_on = [
    kubernetes_cluster_role.linkerd_proxy_injector,
    kubernetes_cluster_role_binding.linkerd_proxy_injector,
    kubernetes_service_account.linkerd_proxy_injector
  ]

  metadata {
    name      = "linkerd-proxy-injector"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.common_linkerd_annotations
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "proxy-injector"
      port        = 443
      target_port = "proxy-injector"
    }
    selector = {
      "linkerd.io/control-plane-component" = "proxy-injector"
    }
  }
}

resource "kubernetes_deployment" "linkerd_proxy_injector" {
  depends_on = [
    kubernetes_cluster_role.linkerd_proxy_injector,
    kubernetes_cluster_role_binding.linkerd_proxy_injector,
    kubernetes_service_account.linkerd_proxy_injector
  ]

  metadata {
    name      = "linkerd-proxy-injector"
    namespace = "linkerd"
    labels = {
      "app.kubernetes.io/name"             = "proxy-injector",
      "app.kubernetes.io/part-of"          = "Linkerd",
      "app.kubernetes.io/version"          = "stable-2.8.1",
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.common_linkerd_annotations
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "linkerd.io/control-plane-component" = "proxy-injector"
      }
    }
    template {
      metadata {
        labels = {
          "linkerd.io/control-plane-component" = "proxy-injector",
          "linkerd.io/control-plane-ns"        = "linkerd",
          "linkerd.io/proxy-deployment"        = "linkerd-proxy-injector",
          "linkerd.io/workload-ns"             = "linkerd"
        }
        annotations = {
          "linkerd.io/created-by"    = "linkerd/cli stable-2.8.1",
          "linkerd.io/identity-mode" = "default",
          "linkerd.io/proxy-version" = "stable-2.8.1"
        }
      }
      spec {
        volume {
          name = "config"
          config_map {
            name = "linkerd-config"
          }
        }
        volume {
          name = "tls"
          secret {
            secret_name = "linkerd-proxy-injector-tls"
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
          image = "gcr.io/linkerd-io/proxy-init:v1.3.3"
          args = [
            "--incoming-proxy-port",
            "4143",
            "--outgoing-proxy-port",
            "4140",
            "--proxy-uid",
            "2102",
            "--inbound-ports-to-ignore",
            "4190,4191",
            "--outbound-ports-to-ignore",
            "443"
          ]
          resources {
            limits {
              memory = "50Mi"
              cpu    = "100m"
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
          name  = "proxy-injector"
          image = "gcr.io/linkerd-io/controller:stable-2.8.1"
          args  = ["proxy-injector", "-log-level=info"]
          port {
            name           = "proxy-injector"
            container_port = 8443
          }
          port {
            name           = "admin-http"
            container_port = 9995
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
          volume_mount {
            name       = "tls"
            read_only  = true
            mount_path = "/var/run/linkerd/tls"
          }
          liveness_probe {
            http_get {
              path = "/ping"
              port = "9995"
            }
            initial_delay_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "9995"
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
          image = "gcr.io/linkerd-io/proxy:stable-2.8.1"
          port {
            name           = "linkerd-proxy"
            container_port = 4143
          }
          port {
            name           = "linkerd-admin"
            container_port = 4191
          }
          env {
            name  = "LINKERD2_PROXY_LOG"
            value = "warn,linkerd=info"
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_SVC_ADDR"
            value = "linkerd-dst.linkerd.svc.cluster.local:8086"
          }
          env {
            name  = "LINKERD2_PROXY_DESTINATION_GET_NETWORKS"
            value = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
          }
          env {
            name  = "LINKERD2_PROXY_CONTROL_LISTEN_ADDR"
            value = "0.0.0.0:4190"
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
        service_account_name = "linkerd-proxy-injector"
        # affinity {
        #   pod_anti_affinity {
        #     required_during_scheduling_ignored_during_execution {
        #       label_selector {
        #         match_expressions {
        #           key      = "linkerd.io/control-plane-component"
        #           operator = "In"
        #           values   = ["proxy-injector"]
        #         }
        #       }
        #       topology_key = "kubernetes.io/hostname"
        #     }
        #     preferred_during_scheduling_ignored_during_execution {
        #       weight = 100
        #       pod_affinity_term {
        #         label_selector {
        #           match_expressions {
        #             key      = "linkerd.io/control-plane-component"
        #             operator = "In"
        #             values   = ["proxy-injector"]
        #           }
        #         }
        #         topology_key = "failure-domain.beta.kubernetes.io/zone"
        #       }
        #     }
        #   }
        # }
      }
    }
    strategy {
      rolling_update {
        max_unavailable = "1"
      }
    }
  }
}
