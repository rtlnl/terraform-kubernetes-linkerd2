resource "kubernetes_role" "linkerd_web" {
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    })
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
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = local.linkerd_web_name
  }
}

resource "kubernetes_cluster_role" "linkerd_web_check" {
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name = "linkerd-linkerd-web-check"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    })
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
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name = "linkerd-linkerd-web-check"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-web-check"
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_web_admin" {
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name = "linkerd-linkerd-web-admin"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-tap-admin"
  }
}

resource "kubernetes_service_account" "linkerd_web" {
  metadata {
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    })
  }
}

resource "kubernetes_service" "linkerd_web" {
  depends_on = [
    kubernetes_namespace.linkerd,
    kubernetes_role.linkerd_web,
    kubernetes_role_binding.linkerd_web,
    kubernetes_cluster_role.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_linkerd_web_admin,
    kubernetes_service_account.linkerd_web
  ]

  metadata {
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    })
    annotations = local.linkerd_annotation_created_by
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
      "linkerd.io/control-plane-component" = local.linkerd_component_web_name
    }
  }
}

resource "kubernetes_deployment" "linkerd_web" {
  depends_on = [
    kubernetes_namespace.linkerd,
    kubernetes_role.linkerd_web,
    kubernetes_role_binding.linkerd_web,
    kubernetes_cluster_role.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_web_check,
    kubernetes_cluster_role_binding.linkerd_linkerd_web_admin,
    kubernetes_service_account.linkerd_web,
    kubernetes_deployment.linkerd_identity
  ]

  metadata {
    name      = local.linkerd_web_name
    namespace = local.linkerd_namespace
    labels    = merge(
      local.linkerd_label_control_plane_ns,
      local.linkerd_label_partof_version,
      {
        "app.kubernetes.io/name"             = local.linkerd_component_web_name,
        "linkerd.io/control-plane-component" = local.linkerd_component_web_name
      }
    )
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    replicas = 1
    selector {
      match_labels = merge(local.linkerd_label_control_plane_ns, {
        "linkerd.io/control-plane-component" = local.linkerd_component_web_name,
        "linkerd.io/proxy-deployment"        = local.linkerd_web_name
      })
    }
    template {
      metadata {
        labels = merge(
          local.linkerd_label_control_plane_ns,
          local.linkerd_label_workload_ns,
          {
            "linkerd.io/control-plane-component" = local.linkerd_component_web_name,
            "linkerd.io/proxy-deployment"        = local.linkerd_web_name
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
          name  = local.linkerd_component_web_name
          image = "gcr.io/linkerd-io/web:stable-2.8.1"
          args = [
            "-api-addr=linkerd-controller-api.linkerd.svc.cluster.local:8085",
            "-grafana-addr=linkerd-grafana.linkerd.svc.cluster.local:3000",
            "-controller-namespace=${local.linkerd_namespace}",
            "-log-level=${local.linkerd_container_log_level}",
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
        service_account_name = local.linkerd_web_name
      }
    }
  }
}

# resource "kubernetes_secret" "linkerd_dashboard_ingress_auth" {
#   metadata {
#     name      = "linkerd-dashboard-ingress-auth"
#     namespace = local.linkerd_namespace
#   }
#   data = {
#     auth = "admin:$apr1$n7Cu6gHl$E47ogf7CO8NRYjEjBOkWM.\n\n"
#   }
#   type = "Opaque"
# }

# resource "kubernetes_ingress" "linkerd_dashboard_ingress" {
#   metadata {
#     name      = "linkerd-dashboard-ingress"
#     namespace = local.linkerd_namespace
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
#             service_name = local.linkerd_web_name
#             service_port = "8084"
#           }
#         }
#       }
#     }
#   }
# }
