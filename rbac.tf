resource "kubernetes_cluster_role" "linkerd_linkerd_identity" {
  metadata {
    name = "linkerd-linkerd-identity"
    labels = {
      "linkerd.io/control-plane-component" = "identity",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["create"]
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
  }
  rule {
    verbs      = ["get"]
    api_groups = ["apps"]
    resources  = ["deployments"]
  }
  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_identity" {
  metadata {
    name = "linkerd-linkerd-identity"
    labels = {
      "linkerd.io/control-plane-component" = "identity",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-identity"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-identity"
  }
}

resource "kubernetes_service_account" "linkerd_identity" {
  metadata {
    name      = "linkerd-identity"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "identity",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_controller" {
  metadata {
    name = "linkerd-linkerd-controller"
    labels = {
      "linkerd.io/control-plane-component" = "controller",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "apps"]
    resources  = ["daemonsets", "deployments", "replicasets", "statefulsets"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "batch"]
    resources  = ["cronjobs", "jobs"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = [""]
    resources  = ["pods", "endpoints", "services", "replicationcontrollers", "namespaces"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["linkerd.io"]
    resources  = ["serviceprofiles"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["split.smi-spec.io"]
    resources  = ["trafficsplits"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_controller" {
  metadata {
    name = "linkerd-linkerd-controller"
    labels = {
      "linkerd.io/control-plane-component" = "controller",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-controller"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-controller"
  }
}

resource "kubernetes_service_account" "linkerd_controller" {
  metadata {
    name      = "linkerd-controller"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "controller",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_destination" {
  metadata {
    name = "linkerd-linkerd-destination"
    labels = {
      "linkerd.io/control-plane-component" = "destination",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["apps"]
    resources  = ["replicasets"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["batch"]
    resources  = ["jobs"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = [""]
    resources  = ["pods", "endpoints", "services"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["linkerd.io"]
    resources  = ["serviceprofiles"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["split.smi-spec.io"]
    resources  = ["trafficsplits"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_destination" {
  metadata {
    name = "linkerd-linkerd-destination"
    labels = {
      "linkerd.io/control-plane-component" = "destination",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-destination"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-destination"
  }
}

resource "kubernetes_service_account" "linkerd_destination" {
  metadata {
    name      = "linkerd-destination"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "destination",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_role" "linkerd_heartbeat" {
  metadata {
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-ns" = "linkerd"
    }
  }
  rule {
    verbs          = ["get"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["linkerd-config"]
  }
}

resource "kubernetes_role_binding" "linkerd_heartbeat" {
  metadata {
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-ns" = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "linkerd-heartbeat"
  }
}

resource "kubernetes_service_account" "linkerd_heartbeat" {
  metadata {
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "heartbeat",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_role" "linkerd_web" {
  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs          = ["get"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["linkerd-config"]
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["namespaces", "configmaps"]
  }
  rule {
    verbs      = ["list"]
    api_groups = [""]
    resources  = ["serviceaccounts", "pods"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["apps"]
    resources  = ["replicasets"]
  }
}

resource "kubernetes_role_binding" "linkerd_web" {
  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-web"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "linkerd-web"
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_web_check" {
  metadata {
    name = "linkerd-linkerd-web-check"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["list"]
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterroles", "clusterrolebindings"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["policy"]
    resources  = ["podsecuritypolicies"]
  }
  rule {
    verbs      = ["list"]
    api_groups = ["linkerd.io"]
    resources  = ["serviceprofiles"]
  }
  rule {
    verbs      = ["get"]
    api_groups = ["apiregistration.k8s.io"]
    resources  = ["apiservices"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_web_check" {
  metadata {
    name = "linkerd-linkerd-web-check"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-web"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-web-check"
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_web_admin" {
  metadata {
    name = "linkerd-linkerd-web-admin"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-web"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-tap-admin"
  }
}

resource "kubernetes_service_account" "linkerd_web" {
  metadata {
    name      = "linkerd-web"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "web",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_prometheus" {
  metadata {
    name = "linkerd-linkerd-prometheus"
    labels = {
      "linkerd.io/control-plane-component" = "prometheus",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "pods"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_prometheus" {
  metadata {
    name = "linkerd-linkerd-prometheus"
    labels = {
      "linkerd.io/control-plane-component" = "prometheus",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-prometheus"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-prometheus"
  }
}

resource "kubernetes_service_account" "linkerd_prometheus" {
  metadata {
    name      = "linkerd-prometheus"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "prometheus",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_proxy_injector" {
  metadata {
    name = "linkerd-linkerd-proxy-injector"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = [""]
    resources  = ["namespaces", "replicationcontrollers"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["pods"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "batch"]
    resources  = ["cronjobs", "jobs"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_proxy_injector" {
  metadata {
    name = "linkerd-linkerd-proxy-injector"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-proxy-injector"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-proxy-injector"
  }
}

resource "kubernetes_service_account" "linkerd_proxy_injector" {
  metadata {
    name      = "linkerd-proxy-injector"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "proxy-injector",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_sp_validator" {
  metadata {
    name = "linkerd-linkerd-sp-validator"
    labels = {
      "linkerd.io/control-plane-component" = "sp-validator",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["list"]
    api_groups = [""]
    resources  = ["pods"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_sp_validator" {
  metadata {
    name = "linkerd-linkerd-sp-validator"
    labels = {
      "linkerd.io/control-plane-component" = "sp-validator",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-sp-validator"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-sp-validator"
  }
}

resource "kubernetes_service_account" "linkerd_sp_validator" {
  metadata {
    name      = "linkerd-sp-validator"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "sp-validator",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_tap" {
  metadata {
    name = "linkerd-linkerd-tap"
    labels = {
      "linkerd.io/control-plane-component" = "tap",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = [""]
    resources  = ["pods", "services", "replicationcontrollers", "namespaces", "nodes"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "apps"]
    resources  = ["daemonsets", "deployments", "replicasets", "statefulsets"]
  }
  rule {
    verbs      = ["list", "get", "watch"]
    api_groups = ["extensions", "batch"]
    resources  = ["cronjobs", "jobs"]
  }
}

resource "kubernetes_cluster_role" "linkerd_linkerd_tap_admin" {
  metadata {
    name = "linkerd-linkerd-tap-admin"
    labels = {
      "linkerd.io/control-plane-component" = "tap",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  rule {
    verbs      = ["watch"]
    api_groups = ["tap.linkerd.io"]
    resources  = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_tap" {
  metadata {
    name = "linkerd-linkerd-tap"
    labels = {
      "linkerd.io/control-plane-component" = "tap",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-tap"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "linkerd-linkerd-tap"
  }
}

resource "kubernetes_cluster_role_binding" "linkerd_linkerd_tap_auth_delegator" {
  metadata {
    name = "linkerd-linkerd-tap-auth-delegator"
    labels = {
      "linkerd.io/control-plane-component" = "tap",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-tap"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
}

resource "kubernetes_service_account" "linkerd_tap" {
  metadata {
    name      = "linkerd-tap"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-component" = "tap",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
}

resource "kubernetes_role_binding" "linkerd_linkerd_tap_auth_reader" {
  metadata {
    name      = "linkerd-linkerd-tap-auth-reader"
    namespace = "kube-system"
    labels = {
      "linkerd.io/control-plane-component" = "tap",
      "linkerd.io/control-plane-ns"        = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-tap"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }
}

resource "kubernetes_role" "linkerd_psp" {
  metadata {
    name      = "linkerd-psp"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-ns" = "linkerd"
    }
  }
  rule {
    verbs          = ["use"]
    api_groups     = ["policy", "extensions"]
    resources      = ["podsecuritypolicies"]
    resource_names = ["linkerd-linkerd-control-plane"]
  }
}

resource "kubernetes_role_binding" "linkerd_psp" {
  metadata {
    name      = "linkerd-psp"
    namespace = "linkerd"
    labels = {
      "linkerd.io/control-plane-ns" = "linkerd"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-controller"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-destination"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-grafana"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-heartbeat"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-identity"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-prometheus"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-proxy-injector"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-sp-validator"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-tap"
    namespace = "linkerd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "linkerd-web"
    namespace = "linkerd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "linkerd-psp"
  }
}
