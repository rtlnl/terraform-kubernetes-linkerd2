resource "kubernetes_secret" "linkerd_proxy_injector_tls" {
  metadata {
    name      = "linkerd-proxy-injector-tls"
    namespace = local.linkerd_namespace
    labels = {
      "linkerd.io/control-plane-component" = local.linkerd_component_proxy_injector_name,
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.linkerd_annotation_created_by
  }
  type = "Opaque"
  data = {
    "crt.pem" = file("${path.module}/certs/proxy_injector_crt.pem"),
    "key.pem" = file("${path.module}/certs/proxy_injector_key.pem")
  }
}

resource "kubernetes_secret" "linkerd_sp_validator_tls" {
  metadata {
    name      = "linkerd-sp-validator-tls"
    namespace = local.linkerd_namespace
    labels = {
      "linkerd.io/control-plane-component" = local.linkerd_component_sp_validator_name,
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.linkerd_annotation_created_by
  }
  type = "Opaque"
  data = {
    "crt.pem" = file("${path.module}/certs/sp_validator_crt.pem"),
    "key.pem" = file("${path.module}/certs/sp_validator_key.pem")
  }
}

resource "kubernetes_secret" "linkerd_tap_tls" {
  metadata {
    name      = "linkerd-tap-tls"
    namespace = local.linkerd_namespace
    labels = {
      "linkerd.io/control-plane-component" = local.linkerd_component_tap_name,
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.linkerd_annotation_created_by
  }
  type = "Opaque"
  data = {
    "crt.pem" = file("${path.module}/certs/tap_crt.pem"),
    "key.pem" = file("${path.module}/certs/tap_key.pem")
  }
}

resource "kubernetes_secret" "linkerd_identity_issuer" {
  count = var.external_identity_issuer ? 0 : 1 

  metadata {
    name      = "linkerd-identity-issuer"
    namespace = local.linkerd_namespace
    labels = {
      "linkerd.io/control-plane-component" = local.linkerd_component_identity_name,
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = {
      "linkerd.io/created-by"             = "linkerd/helm stable-2.8.1",
      "linkerd.io/identity-issuer-expiry" = "2021-06-30T08:06:46Z"
    }
  }
  data = {
    "crt.pem" = file("${path.module}/certs/identity_issuer_crt.pem"),
    "key.pem" = file("${path.module}/certs/identity_issuer_key.pem")
  }
}
