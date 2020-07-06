locals {
    common_linkerd_annotations = {
        "linkerd.io/created-by" = "linkerd/cli stable-2.8.1"
    }
    
    common_linkerd_labels = {
        "linkerd.io/control-plane-ns" = "linkerd"
    }
}
