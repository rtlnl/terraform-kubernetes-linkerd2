locals {
    linkerd_annotation_created_by = {
        "linkerd.io/created-by" = "linkerd/cli stable-2.8.1"
    }
    
    linkerd_label_control_plane_ns = {
        "linkerd.io/control-plane-ns" = "linkerd"
    }

    linkerd_label_workload_ns = {
        "linkerd.io/workload-ns" = "linkerd"
    }

    linkerd_label_partof_version = {
        "app.kubernetes.io/part-of" = "Linkerd",
        "app.kubernetes.io/version" = "stable-2.8.1"
    }
}
