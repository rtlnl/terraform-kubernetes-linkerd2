resource "kubernetes_role" "linkerd_heartbeat" {
  metadata {
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
    labels    = local.linkerd_label_control_plane_ns
  }
  rule {
    verbs          = ["get"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["linkerd-config"]
  }
}

resource "kubernetes_role_binding" "linkerd_heartbeat" {
  metadata {
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
    labels    = local.linkerd_label_control_plane_ns
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "linkerd-heartbeat"
  }
}

resource "kubernetes_service_account" "linkerd_heartbeat" {
  metadata {
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = "heartbeat"
    })
  }
}

resource "kubernetes_cron_job" "linkerd_heartbeat" {
  depends_on = [
    kubernetes_role.linkerd_heartbeat,
    kubernetes_role_binding.linkerd_heartbeat,
    kubernetes_service_account.linkerd_heartbeat
  ]

  metadata {
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
    labels    = merge(
      local.linkerd_label_control_plane_ns,
      local.linkerd_label_partof_version,
      {
        "app.kubernetes.io/name"             = "heartbeat",
        "linkerd.io/control-plane-component" = "heartbeat",
      }
    )
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    schedule = "16 8 * * * "
    job_template {
      metadata {
      }
      spec {
        template {
          metadata {
            labels = merge(local.linkerd_label_workload_ns, {
              "linkerd.io/control-plane-component" = "heartbeat"
            })
            annotations = local.linkerd_annotation_created_by
          }
          spec {
            automount_service_account_token = var.automount_service_account_token
            container {
              name  = "heartbeat"
              image = "gcr.io/linkerd-io/controller:stable-2.8.1"
              args = [
                "heartbeat",
                "-prometheus-url=http://linkerd-prometheus.linkerd.svc.cluster.local:9090",
                "-controller-namespace=linkerd",
                "-log-level=info"
              ]
              resources {
                limits {
                  memory = "250Mi"
                  cpu    = "1"
                }
                requests {
                  cpu    = "100m"
                  memory = "50Mi"
                }
              }
              image_pull_policy = "IfNotPresent"
              security_context {
                run_as_user = 2103
              }
            }
            restart_policy = "Never"
            node_selector = {
              "beta.kubernetes.io/os" = "linux"
            }
            service_account_name = "linkerd-heartbeat"
          }
        }
      }
    }
  }
}
