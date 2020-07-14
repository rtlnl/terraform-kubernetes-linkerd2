locals {
    linkerd_namespace = "linkerd"

    linkerd_annotation_created_by = {
        "linkerd.io/created-by" = "linkerd/cli stable-2.8.1"
    }

    linkerd_annotations_for_deployment = {
        "linkerd.io/created-by"    = "linkerd/cli stable-2.8.1",
        "linkerd.io/identity-mode" = "default",
        "linkerd.io/proxy-version" = "stable-2.8.1"
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

    linkerd_deployment_proxy_image = "gcr.io/linkerd-io/proxy:stable-2.8.1"
    linkerd_deployment_proxy_init_image = "gcr.io/linkerd-io/proxy-init:v1.3.3"
    linkerd_deployment_controller_image = "gcr.io/linkerd-io/controller:stable-2.8.1"

    linkerd_deployment_incoming_proxy_port = 4143
    linkerd_deployment_outgoing_proxy_port = 4140
    linkerd_deployment_proxy_uid = 2102
    linkerd_deployment_proxy_control_port = 4190
    linkerd_deployment_admin_port = 4191
    linkerd_deployment_outbound_port = 433
}
