resource "kubernetes_validating_webhook_configuration" "linkerd_sp_validator" {
  metadata {
    name = "linkerd-sp-validator-webhook-config"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_sp_validator_name
    })
  }
  webhook {
    name = "linkerd-sp-validator.linkerd.io"
    namespace_selector {
      match_expressions {
        key      = "config.linkerd.io/admission-webhooks"
        operator = "NotIn"
        values   = ["disabled"]
      }
    }
    client_config {
      service {
        name      = local.linkerd_sp_validator_name
        namespace = local.linkerd_namespace
        path      = "/"
      }
      ca_bundle = base64encode(local.validating_webhook_ca_bundle)
    }
    failure_policy = "Ignore"
    rule {
      api_groups   = ["linkerd.io"]
      api_versions = ["v1alpha1", "v1alpha2"]
      operations   = ["CREATE", "UPDATE"]
      resources    = ["serviceprofiles"]
    }
    side_effects = "None"
  }
}

resource "kubernetes_mutating_webhook_configuration" "linkerd_proxy_injector" {
  metadata {
    name = "linkerd-proxy-injector-webhook-config"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "linkerd.io/control-plane-component" = local.linkerd_proxy_injector_name
    })
  }
  webhook {
    name = "linkerd-proxy-injector.linkerd.io"
    namespace_selector {
      match_expressions {
        key      = "config.linkerd.io/admission-webhooks"
        operator = "NotIn"
        values   = ["disabled"]
      }
    }
    client_config {
      service {
        name      = local.linkerd_proxy_injector_name
        namespace = local.linkerd_namespace
        path      = "/"
      }
      ca_bundle = base64encode(local.mutating_webhook_ca_bundle)
    }
    rule {
      api_groups   = [""]
      api_versions = ["v1"]
      operations   = ["CREATE"]
      resources    = ["pods"]
    }
    side_effects = "None"
  }
}
