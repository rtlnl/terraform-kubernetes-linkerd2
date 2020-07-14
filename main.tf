resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
    labels = merge(local.linkerd_label_control_plane_ns, {
      "config.linkerd.io/admission-webhooks" = "disabled",
      "linkerd.io/is-control-plane"          = "true"
    })
    annotations = {
      "linkerd.io/inject" = "disabled"
    }
  }
}

resource "kubernetes_config_map" "linkerd_config" {
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name      = "linkerd-config"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "controller",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
    annotations = local.linkerd_annotation_created_by
  }
  data = {
    global  = file("${path.module}/configs/global")
    install = file("${path.module}/configs/install")
    proxy   = file("${path.module}/configs/proxy")
  }
}

resource "kubernetes_config_map" "linkerd_config_addons" {
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name      = "linkerd-config-addons"
    namespace = "linkerd"
    labels    = local.linkerd_label_control_plane_ns
    annotations = local.linkerd_annotation_created_by
  }
  data = {
    values = file("${path.module}/configs/addon_values")
  }
}
