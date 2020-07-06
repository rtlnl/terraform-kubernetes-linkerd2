resource "kubernetes_role" "linkerd_web" {
  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs          = ["get"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["linkerd-config"]
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["namespaces", "configmaps"]
  }
  rule {
    verbs      = ["list"]
    api_groups = [""]
    resources  = ["serviceaccounts", "pods"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["apps"]
    resources  = ["replicasets"]
  }
}

resource "kubernetes_role_binding" "linkerd_web" {
  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-web"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "linkerd-web"
  }
}

resource "kubernetes_cluster_role" "linkerd_web_check" {
  metadata {
    name = "linkerd-linkerd-web-check"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["list"]
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterroles", "clusterrolebindings"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["policy"]
    resources  = ["podsecuritypolicies"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["linkerd.io"]
    resources  = ["serviceprofiles"]
  }
  rule {
    verbs      = ["get"]
    api_groups = ["apiregistration.k8s.io"]
    resources  = ["apiservices"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_web_check" {
  metadata {
    name = "linkerd-linkerd-web-check"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-web"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-web-check"
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_web_admin" {
  metadata {
    name = "linkerd-linkerd-web-admin"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-web"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-tap-admin"
  }
}

resource "kubernetes_service_account" "linkerd_web" {
  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_service" "linkerd_web" {
  depends_on = [
    kubernetes_role.linkerd_web,
    kubernetes_role_binding.linkerd_web,
    kubernetes_cluster_role.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_linkerd_web_admin,
    kubernetes_service_account.linkerd_web
  ]

  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.common_linkerd_annotations
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "http"
      port        = 8084
      target_port = "8084"
    }
    port {
      name        = "admin-http"
      port        = 9994
      target_port = "9994"
    }
    selector = {
      "linkerd.io/control-plane-component" = "web"
    }
  }
}

resource "kubernetes_deployment" "linkerd_web" {
  depends_on = [
    kubernetes_role.linkerd_web,
    kubernetes_role_binding.linkerd_web,
    kubernetes_cluster_role.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_linkerd_web_admin,
    kubernetes_service_account.linkerd_web
  ]

  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "app.kubernetes.io/name"             = "web",
      "app.kubernetes.io/part-of"          = "Linkerd",
      "app.kubernetes.io/version"          = "stable-2.8.1",
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.common_linkerd_annotations
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "linkerd.io/control-plane-component" = "web",
        "linkerd.io/control-plane-ns"        = "linkerd",
        "linkerd.io/proxy-deployment"        = "linkerd-web"
      }
    }
    template {
      metadata {
        labels = {
          "linkerd.io/control-plane-component" = "web",
          "linkerd.io/control-plane-ns"        = "linkerd",
          "linkerd.io/proxy-deployment"        = "linkerd-web",
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
          name = "linkerd-identity-end-entity"
          empty_dir {
            medium = "Memory"
          }
        }
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
          name  = "web"
          image = "gcr.io/linkerd-io/web:stable-2.8.1"
          args = [
            "-api-addr=linkerd-controller-api.linkerd.svc.cluster.local:8085",
            "-grafana-addr=linkerd-grafana.linkerd.svc.cluster.local:3000",
            "-controller-namespace=linkerd",
            "-log-level=info",
            "-enforced-host=^(localhost|127\\.0\\.0\\.1|linkerd-web\\.linkerd\\.svc\\.cluster\\.local|linkerd-web\\.linkerd\\.svc|\\[::1\\])(:\\d+)?$"
          ]
          port {
            name           = "http"
            container_port = 8084
          }
          port {
            name           = "admin-http"
            container_port = 9994
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
              port = "9994"
            }
            initial_delay_seconds = 10
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "9994"
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
            value = "${file("${path.module}/certs/proxy_trust_anchor.cert")}"
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
        service_account_name = "linkerd-web"
      }
    }
  }
}

# resource "kubernetes_secret" "linkerd_dashboard_ingress_auth" {
#   metadata {
#     name      = "linkerd-dashboard-ingress-auth"
#     namespace = "linkerd"
#   }
#   data = {
#     auth = "admin:$apr1$n7Cu6gHl$E47ogf7CO8NRYjEjBOkWM.\n\n"
#   }
#   type = "Opaque"
# }

# resource "kubernetes_ingress" "linkerd_dashboard_ingress" {
#   metadata {
#     name      = "linkerd-dashboard-ingress"
#     namespace = "linkerd"
#     annotations = {
#       "kubernetes.io/ingress.class"                       = "nginx"
#       "nginx.ingress.kubernetes.io/auth-realm"            = "Authentication Required"
#       "nginx.ingress.kubernetes.io/auth-secret"           = "linkerd-dashboard-ingress-auth"
#       "nginx.ingress.kubernetes.io/auth-type"             = "basic"
#       "nginx.ingress.kubernetes.io/configuration-snippet" = "proxy_set_header Origin \"\";\nproxy_hide_header l5d-remote-ip;\nproxy_hide_header l5d-server-id; \n"
#       "nginx.ingress.kubernetes.io/ssl-passthrough"       = "true"
#       "nginx.ingress.kubernetes.io/ssl-redirect"          = "false"
#       "nginx.ingress.kubernetes.io/upstream-vhost"        = "$service_name.$namespace.svc.cluster.local:8084"
#     }
#   }
#   spec {
#     rule {
#       host = "linkerd-dashboard.rtl-di.nl"
#       http {
#         path {
#           backend {
#             service_name = "linkerd-web"
#             service_port = "8084"
#           }
#         }
#       }
#     }
#   }
# }
