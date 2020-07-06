resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
    labels = {
      "config.linkerd.io/admission-webhooks" = "disabled",
      "linkerd.io/control-plane-ns"          = "linkerd",
      "linkerd.io/is-control-plane"          = "true"
    }
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
    annotations = local.common_linkerd_annotations
  }
  data = {
    global  = "${file("${path.module}/configs/global")}"
    install = "${file("${path.module}/configs/install")}"
    proxy   = "${file("${path.module}/configs/proxy")}"
  }
}

resource "kubernetes_config_map" "linkerd_config_addons" {
  depends_on = [kubernetes_namespace.linkerd]

  metadata {
    name      = "linkerd-config-addons"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-ns" = "linkerd"
    }
    annotations = local.common_linkerd_annotations
  }
  data = {
    values = "${file("${path.module}/configs/addon_values")}"
  }
}
