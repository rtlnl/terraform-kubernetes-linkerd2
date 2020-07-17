resource "kubernetes_cluster_role" "linkerd_prometheus" {
  metadata {
    name = "linkerd-linkerd-prometheus"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name
    })
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "pods"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_prometheus" {
  metadata {
    name = "linkerd-linkerd-prometheus"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name
    })
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.linkerd_prometheus_name
    namespace = local.linkerd_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-prometheus"
  }
}

resource "kubernetes_service_account" "linkerd_prometheus" {
  metadata {
    name      = local.linkerd_prometheus_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name
    })
  }
}

resource "kubernetes_config_map" "linkerd_prometheus_config" {
  depends_on = [
    kubernetes_cluster_role.linkerd_prometheus,
    kubernetes_cluster_role_binding.linkerd_prometheus,
    kubernetes_service_account.linkerd_prometheus
  ]

  metadata {
    name      = "linkerd-prometheus-config"
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name
    })
    annotations = local.linkerd_annotation_created_by
  }
  data = {
    "prometheus.yml" = file("${path.module}/prometheus/config.yaml")
  }
}

resource "kubernetes_service" "linkerd_prometheus" {
  depends_on = [
    kubernetes_config_map.linkerd_prometheus_config,
    kubernetes_cluster_role.linkerd_prometheus,
    kubernetes_cluster_role_binding.linkerd_prometheus,
    kubernetes_service_account.linkerd_prometheus
  ]

  metadata {
    name      = local.linkerd_prometheus_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name
    })
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "admin-http"
      port        = 9090
      target_port = "9090"
    }
    selector = {
      "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name
    }
  }
}

resource "kubernetes_deployment" "linkerd_prometheus" {
  depends_on = [
    kubernetes_config_map.linkerd_prometheus_config,
    kubernetes_cluster_role.linkerd_prometheus,
    kubernetes_cluster_role_binding.linkerd_prometheus,
    kubernetes_service_account.linkerd_prometheus
  ]

  metadata {
    name      = local.linkerd_prometheus_name
    namespace = local.linkerd_namespace
    labels = merge(
      local.linkerd_label_control_plane_ns,
      local.linkerd_label_partof_version,
      {
        "app.kubernetes.io/name"             = local.linkerd_component_prometheus_name,
        "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name
      }
    )
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    replicas = 1
    selector {
      match_labels = merge(local.linkerd_label_control_plane_ns, {
        "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name,
        "linkerd.io/proxy-deployment"        = local.linkerd_prometheus_name
      })
    }
    template {
      metadata {
        labels = merge(
          local.linkerd_label_control_plane_ns,
          local.linkerd_label_workload_ns,
          {
            "linkerd.io/control-plane-component" = local.linkerd_component_prometheus_name,
            "linkerd.io/proxy-deployment"        = local.linkerd_prometheus_name
          }
        )
        annotations = local.linkerd_annotations_for_deployment
      }
      spec {
        volume {
          name = "data"
        }
        volume {
          name = "prometheus-config"
          config_map {
            name = "linkerd-prometheus-config"
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
          name  = local.linkerd_component_prometheus_name
          image = "prom/prometheus:v2.15.2"
          args  = ["--storage.tsdb.path=/data", "--storage.tsdb.retention.time=6h", "--config.file=/etc/prometheus/prometheus.yml", "--log.level=info"]
          port {
            name           = "admin-http"
            container_port = 9090
          }
          resources {
            limits {
              cpu    = "4"
              memory = "8Gi"
            }
            requests {
              cpu    = "300m"
              memory = "300Mi"
            }
          }
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
          volume_mount {
            name       = "prometheus-config"
            read_only  = true
            mount_path = "/etc/prometheus/prometheus.yml"
            sub_path   = "prometheus.yml"
          }
          liveness_probe {
            http_get {
              path = "/-/healthy"
              port = "9090"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }
          readiness_probe {
            http_get {
              path = "/-/ready"
              port = "9090"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user = 65534
          }
        }
        container {
          name  = "linkerd-proxy"
          image = local.linkerd_deployment_proxy_image
          port {
            name           = local.linkerd_deployment_proxy_port_name
            container_port = local.linkerd_deployment_incoming_proxy_port
          }
          port {
            name           = local.linkerd_deployment_admin_port_name
            container_port = local.linkerd_deployment_admin_port
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
            name  = "LINKERD2_PROXY_OUTBOUND_ROUTER_CAPACITY"
            value = "10000"
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
        service_account_name = local.linkerd_prometheus_name
      }
    }
  }
}
