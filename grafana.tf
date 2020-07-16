resource "kubernetes_service_account" "linkerd_grafana" {
  metadata {
    name      = local.linkerd_grafana_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_grafana_name
    })
  }
}

resource "kubernetes_config_map" "linkerd_grafana_config" {

  depends_on = [kubernetes_service_account.linkerd_grafana]

  metadata {
    name      = "linkerd-grafana-config"
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_grafana_name
    })
    annotations = local.linkerd_annotation_created_by
  }
  data = {
    "grafana.ini"      = file("${path.module}/grafana/grafana.ini")
    "datasources.yaml" = file("${path.module}/grafana/datasources.yaml")
    "dashboards.yaml"  = file("${path.module}/grafana/dashboards.yaml")
  }
}

resource "kubernetes_service" "linkerd_grafana" {
  depends_on = [kubernetes_config_map.linkerd_grafana_config]

  metadata {
    name      = local.linkerd_grafana_name
    namespace = local.linkerd_namespace
    labels    = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_component_grafana_name
    })
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "http"
      port        = 3000
      target_port = "3000"
    }
    selector = {
      "linkerd.io/control-plane-component" = local.linkerd_component_grafana_name
    }
  }
}

resource "kubernetes_deployment" "linkerd_grafana" {
  depends_on = [kubernetes_config_map.linkerd_grafana_config]

  metadata {
    name      = local.linkerd_grafana_name
    namespace = local.linkerd_namespace
    labels    = merge(
      local.linkerd_label_control_plane_ns,
      local.linkerd_label_partof_version,
      {
        "app.kubernetes.io/name"             = local.linkerd_component_grafana_name,
        "linkerd.io/control-plane-component" = local.linkerd_component_grafana_name
      }
    )
    annotations = local.linkerd_annotation_created_by
  }
  spec {
    replicas = 1
    selector {
      match_labels = merge(local.linkerd_label_control_plane_ns, {
        "linkerd.io/control-plane-component" = local.linkerd_component_grafana_name,
        "linkerd.io/proxy-deployment"        = local.linkerd_grafana_name
      })
    }
    template {
      metadata {
        labels = merge(
          local.linkerd_label_control_plane_ns,
          local.linkerd_label_workload_ns,
          {
            "linkerd.io/control-plane-component" = local.linkerd_component_grafana_name,
            "linkerd.io/proxy-deployment"        = local.linkerd_grafana_name
          }
        )
        annotations = local.linkerd_annotations_for_deployment
      }
      spec {
        volume {
          name = "data"
        }
        volume {
          name = "grafana-config"
          config_map {
            name = "linkerd-grafana-config"
            items {
              key  = "grafana.ini"
              path = "grafana.ini"
            }
            items {
              key  = "datasources.yaml"
              path = "provisioning/datasources/datasources.yaml"
            }
            items {
              key  = "dashboards.yaml"
              path = "provisioning/dashboards/dashboards.yaml"
            }
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
              memory = "50Mi"
              cpu    = "100m"
            }
            requests {
              memory = "10Mi"
              cpu    = "10m"
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
          name  = local.linkerd_component_grafana_name
          image = "gcr.io/linkerd-io/grafana:stable-2.8.1"
          port {
            name           = "http"
            container_port = 3000
          }
          env {
            name  = "GF_PATHS_DATA"
            value = "/data"
          }
          env {
            name  = "GODEBUG"
            value = "netdns=go"
          }
          resources {
            limits {
              cpu    = "1"
              memory = "1Gi"
            }
            requests {
              memory = "50Mi"
              cpu    = "100m"
            }
          }
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
          volume_mount {
            name       = "grafana-config"
            read_only  = true
            mount_path = "/etc/grafana"
          }
          liveness_probe {
            http_get {
              path = "/api/health"
              port = "3000"
            }
            initial_delay_seconds = 30
          }
          readiness_probe {
            http_get {
              path = "/api/health"
              port = "3000"
            }
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user = 472
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
            value = "linkerd-dst.linkerd.svc.cluster.local:8086"
          }
          env {
            name  = "LINKERD2_PROXY_IDENTITY_SVC_ADDR"
            value = "linkerd-identity.linkerd.svc.cluster.local:8080"
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
        node_selector = {
          "beta.kubernetes.io/os" = "linux"
        }
        service_account_name = local.linkerd_grafana_name
      }
    }
  }
}
