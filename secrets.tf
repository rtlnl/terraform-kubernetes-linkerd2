resource "kubernetes_secret" "linkerd_proxy_injector_tls" {
  metadata {
    name      = "linkerd-proxy-injector-tls"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = {
      "linkerd.io/created-by" = "linkerd/cli stable-2.8.1"
    }
  }
  type = "Opaque"
  data = {
    "crt.pem" = "${file("${path.module}/certs/proxy_injector_crt.pem")}",
    "key.pem" = "${file("${path.module}/certs/proxy_injector_key.pem")}"
  }
}

resource "kubernetes_secret" "linkerd_sp_validator_tls" {
  metadata {
    name      = "linkerd-sp-validator-tls"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "sp-validator",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = {
      "linkerd.io/created-by" = "linkerd/cli stable-2.8.1"
    }
  }
  type = "Opaque"
  data = {
    "crt.pem" = "${file("${path.module}/certs/sp_validator_crt.pem")}",
    "key.pem" = "${file("${path.module}/certs/sp_validator_key.pem")}"
  }
}

resource "kubernetes_secret" "linkerd_tap_tls" {
  metadata {
    name      = "linkerd-tap-tls"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "tap",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = {
      "linkerd.io/created-by" = "linkerd/cli stable-2.8.1"
    }
  }
  type = "Opaque"
  data = {
    "crt.pem" = "${file("${path.module}/certs/tap_crt.pem")}",
    "key.pem" = "${file("${path.module}/certs/tap_key.pem")}"
  }
}

resource "kubernetes_secret" "linkerd_identity_issuer" {
  metadata {
    name      = "linkerd-identity-issuer"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "identity",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = {
      "linkerd.io/created-by"             = "linkerd/cli stable-2.8.1",
      "linkerd.io/identity-issuer-expiry" = "2021-06-30T08:06:46Z"
    }
  }
  data = {
    "crt.pem" = "${file("${path.module}/certs/identity_issuer_crt.pem")}",
    "key.pem" = "${file("${path.module}/certs/identity_issuer_key.pem")}"
  }
}
