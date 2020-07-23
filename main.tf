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

data "template_file" "trust_anchor" {
  template = file("${path.module}/configs/global")

  vars = {
    trustAnchorsPEM = trimspace(replace(local.trustAnchorsPEM, "\n", "\\n"))
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
    global  = trimspace(data.template_file.trust_anchor.rendered)
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
