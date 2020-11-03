![Lint](https://github.com/rtlnl/terraform-kubernetes-linkerd2/workflows/Lint/badge.svg?branch=main)

# Linkerd2 Terraform Module

Terraform module to deploy Linkerd2 on Kubernetes. This modules uses the Terraform Kubernetes provider instead of running the Helm provider.

We ❤️ contributions! Open a PR if you find a bug or you'd like to have a specific feature :rocket:

## Features

The module supports the following features:

- Basic installation
- High Availability
- Automatic rotation of TLS controlplane credentials as explained [here](https://linkerd.io/2/tasks/automatically-rotating-control-plane-tls-credentials/)
- Creation of Web Ingress object for exposing the dashboard

## Roadmap

We are using the module in production and we have the following features that we want to add to the module to make it more flexible:

- Enable/Disable Grafana deployment
- Enable/Disable Prometheus deployment (newer version of Linkerd2)
- Resource customization for each component
- Toleration customizable for the controlplane components

## Test the module locally

We recommend to use `KinD` to test the module. To install KinD run `brew install kind` if you are on macOS. Otherwise, check the [documentation](https://kind.sigs.k8s.io/docs/user/quick-start/) here. Asumming you have a cluster working and `terraform` installed, run:

```bash
$: terraform plan
$: terraform apply -auto-approve
```

The result should look like the following

```
NAME                                      READY   STATUS    RESTARTS   AGE
linkerd-controller-688c9b44fc-nj5k5       2/2     Running   1          5m20s
linkerd-destination-796887566b-w9n24      2/2     Running   1          5m20s
linkerd-grafana-7bc97d557f-6mb45          2/2     Running   0          5m20s
linkerd-identity-6c95fc9987-xhbbw         2/2     Running   1          5m48s
linkerd-prometheus-55cd4d9b7d-lrvj5       2/2     Running   0          5m20s
linkerd-proxy-injector-5c79b898d5-d2tpd   2/2     Running   1          5m20s
linkerd-sp-validator-7c979f95d5-n57jt     2/2     Running   1          5m20s
linkerd-tap-7b7c68cd95-kg4px              2/2     Running   1          5m20s
linkerd-web-789cb74784-ghzvr              2/2     Running   1          5m21s
```

Don't worry if some pods restart. It's normal since terraform takes a little bit to create all the resources. To tear the module down, run `terraform destroy -auto-approve` and that's it.

### High Availability Mode

There is a boolean variable `high_availability` that needs to be set, to switch on high availability in the cluster, this controls when to apply various pod/node affinities defined in the linkerd deployments.

## Certificates

There are some pre-made certificates in the module. This is necessary to make it work locally. We **highly discourage** you to use these in production as they are publicly available. In the `example` folder, we have a small example on how to combine `cert-manager` with `your-own-trustanchors.pem` files to enable the automatic rotation of the controlplane certificates.

## Requirements

| Name       | Version   |
| ---------- | --------- |
| terraform  | >= 0.12.9 |
| kubernetes | >= 1.11.1 |

## Providers

| Name       | Version   |
| ---------- | --------- |
| kubernetes | >= 1.11.1 |
| null       | n/a       |
| template   | n/a       |

## Inputs

| Name                            | Description                                                                                                                                                                                            | Type          | Default                          | Required |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | -------------------------------- | :------: |
| automount_service_account_token | Enable automatic mounting of the service account token                                                                                                                                                 | `bool`        | `true`                           |    no    |
| container_log_level             | container log level                                                                                                                                                                                    | `string`      | `"info"`                         |    no    |
| controller_image                | docker image name for the controller                                                                                                                                                                   | `string`      | `"gcr.io/linkerd-io/controller"` |    no    |
| controller_image_tag            | docker image tag for the controller                                                                                                                                                                    | `string`      | `"stable-2.8.1"`                 |    no    |
| controlplane_ha_replicas        | amount of replicas for the controlplane components when High Availability is enabled                                                                                                                   | `number`      | `3`                              |    no    |
| create_namespace                | create the namespace resource or not                                                                                                                                                                   | `bool`        | `true`                           |    no    |
| enable_web_ingress              | enable the ingress object for the web component                                                                                                                                                        | `bool`        | `false`                          |    no    |
| external_identity_issuer        | Use true in Production! If left to false, it will use the certificates coming with this module. For more information: https://linkerd.io/2/tasks/automatically-rotating-control-plane-tls-credentials/ | `bool`        | `false`                          |    no    |
| grafana_replicas                | number of replicas for grafana component                                                                                                                                                               | `number`      | `1`                              |    no    |
| high_availability               | Enable high availability                                                                                                                                                                               | `bool`        | `false`                          |    no    |
| module_depends_on               | Variable to pass dependancy on external module                                                                                                                                                         | `any`         | `null`                           |    no    |
| namespace_name                  | name of the namespace                                                                                                                                                                                  | `string`      | `"linkerd"`                      |    no    |
| prometheus_replicas             | number of replicas for prometheus component                                                                                                                                                            | `number`      | `1`                              |    no    |
| proxy_image                     | docker image name for the proxy                                                                                                                                                                        | `string`      | `"gcr.io/linkerd-io/proxy"`      |    no    |
| proxy_image_tag                 | docker image tag for the proxy                                                                                                                                                                         | `string`      | `"stable-2.8.1"`                 |    no    |
| proxy_init_image                | docker image name for the proxy_init                                                                                                                                                                   | `string`      | `"gcr.io/linkerd-io/proxy-init"` |    no    |
| proxy_init_image_tag            | docker image tag for the proxy_init                                                                                                                                                                    | `string`      | `"v1.3.3"`                       |    no    |
| proxy_injector_pem              | custom proxy injector pem file. See example file in certs folder on how to pass it as string                                                                                                           | `string`      | `""`                             |    no    |
| sp_validator_pem                | custom sp validator pem file. See example file in certs folder on how to pass it as string                                                                                                             | `string`      | `""`                             |    no    |
| trust_anchors_pem_value         | PEM value used as trust anchors                                                                                                                                                                        | `string`      | `""`                             |    no    |
| trust_domain                    | trust domain for TLS certificates                                                                                                                                                                      | `string`      | `"cluster.local"`                |    no    |
| web_ingress_annotations         | eventual ingress annotations for the ingress-controller                                                                                                                                                | `map(string)` | `{}`                             |    no    |
| web_ingress_host                | host name for the web component                                                                                                                                                                        | `string`      | `""`                             |    no    |
| web_replicas                    | number of replicas for web component                                                                                                                                                                   | `number`      | `1`                              |    no    |

## Outputs

No output.
