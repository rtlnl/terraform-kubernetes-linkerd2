resource "kubernetes_namespace" "linkerd" {
  count = var.create_namespace ? 1 : 0
  
  depends_on = [var.module_depends_on]

  metadata {
    name = var.namespace_name
    labels = merge(local.linkerd_label_control_plane_ns, {
      "config.linkerd.io/admission-webhooks" = "disabled",
      "linkerd.io/is-control-plane"          = "true"
    })
    annotations = {
      "linkerd.io/inject" = "disabled"
    }
  }
}

module "trust_anchors_pem" {
  source    = "github.com/gearnode/terraform-kubernetes-get-secret?ref=v0.3.0"

  namespace = "linkerd"
  name      = "linkerd-identity-issuer"
  key       = "ca.crt"
  context   = "arn:aws:eks:eu-west-1:451291743503:cluster/di-gateway-cluster"
}

data "template_file" "trust_anchor" {
  template = file("${path.module}/configs/global")

  vars = {
    trustAnchorsPEM = module.trust_anchors_pem.result
  }
}

resource "kubernetes_config_map" "linkerd_config" {
  depends_on = [
    kubernetes_namespace.linkerd[0]
  ]

  metadata {
    name      = "linkerd-config"
    namespace = local.linkerd_namespace
    labels = {
      "linkerd.io/control-plane-component" = local.linkerd_component_controller_name,
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.linkerd_annotation_created_by
  }
  data = {
    global  = data.template_file.trust_anchor.rendered
    install = file("${path.module}/configs/install")
    proxy   = file("${path.module}/configs/proxy")
  }
}

resource "kubernetes_config_map" "linkerd_config_addons" {
  depends_on = [kubernetes_namespace.linkerd[0]]

  metadata {
    name      = "linkerd-config-addons"
    namespace = local.linkerd_namespace
    labels    = local.linkerd_label_control_plane_ns
    annotations = local.linkerd_annotation_created_by
  }
  data = {
    values = file("${path.module}/configs/addon_values")
  }
}
