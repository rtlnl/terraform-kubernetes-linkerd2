// Other modules here
// ...

// (Optional) install cert-manager in your kubernetes cluster
module "cert_manager" {
  source = "./path/where/cert-manager/is"
}

// create linkerd namespace to generate trust-anchor
resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
    labels = {
      "linkerd.io/control-plane-ns"          = "linkerd"
      "linkerd.io/is-control-plane"          = "true"
      "config.linkerd.io/admission-webhooks" = "disabled",
    }
    annotations = {
      "linkerd.io/inject" = "disabled"
    }
  }
}

resource "kubernetes_secret" "linkerd_trust_anchor" {
  depends_on = [
    kubernetes_namespace.linkerd
  ]
  metadata {
    name      = "linkerd-trust-anchor"
    namespace = kubernetes_namespace.linkerd.metadata.0.name
  }
  type = "kubernetes.io/tls"
  data = {
    // we encourage to use Vault to store your secrets - here an example on how to use them
    "tls.crt" = data.vault_generic_secret.linkerd.data["ca.crt"]
    "tls.key" = data.vault_generic_secret.linkerd.data["ca.key"]
  }
}

// add trust-anchor
resource "null_resource" "trust_anchor" {
  depends_on = [
    kubernetes_secret.linkerd_trust_anchor
  ]
  triggers = {
    manifest_sha1 = sha1("${data.template_file.trust_anchor.rendered}")
  }
  provisioner "local-exec" {
    command = "kubectl apply -f - <<EOF\n${data.template_file.trust_anchor.rendered}\nEOF"
  }
}

module "linkerd" {
  source = "git::ssh://git@github.com/rtlnl/terraform-aws-linkerd2.git?ref=main"

  module_depends_on = [
    kubernetes_secret.linkerd_trust_anchor
  ]

  external_identity_issuer = true
  high_availability        = true
  trust_anchors_pem_value  = data.vault_generic_secret.linkerd.data["ca.crt"]
  create_namespace         = false
}
