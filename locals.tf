locals {
    linkerd_namespace = "linkerd"

    linkerd_component_controller_name = "controller"
    linkerd_component_destination_name = "destination"
    linkerd_component_grafana_name = "grafana"
    linkerd_component_heartbeat_name = "heartbeat"
    linkerd_component_identity_name = "identity"
    linkerd_component_prometheus_name = "prometheus"
    linkerd_component_proxy_injector_name = "proxy-injector"
    linkerd_component_sp_validator_name = "sp-validator"
    linkerd_component_tap_name = "tap"
    linkerd_component_web_name = "web"

    linkerd_controller_name = "linkerd-controller"
    linkerd_destination_name = "linkerd-destination"
    linkerd_grafana_name = "linkerd-grafana"
    linkerd_heartbeat_name = "linkerd-heartbeat"
    linkerd_identity_name = "linkerd-identity"
    linkerd_prometheus_name = "linkerd-prometheus"
    linkerd_proxy_injector_name = "linkerd-proxy-injector"
    linkerd_sp_validator_name = "linkerd-sp-validator"
    linkerd_tap_name = "linkerd-tap"
    linkerd_web_name = "linkerd-web"

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
