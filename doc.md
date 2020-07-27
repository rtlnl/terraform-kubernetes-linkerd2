## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.9 |
| kubernetes | >= 1.11.1 |

## Providers

| Name | Version |
|------|---------|
| kubernetes | >= 1.11.1 |
| null | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| automount\_service\_account\_token | Enable automatic mounting of the service account token | `bool` | `true` | no |
| container\_log\_level | container log level | `string` | `"info"` | no |
| controller\_image | docker image name for the controller | `string` | `"gcr.io/linkerd-io/controller"` | no |
| controller\_image\_tag | docker image tag for the controller | `string` | `"stable-2.8.1"` | no |
| controlplane\_ha\_replicas | amount of replicas for the controlplane components when High Availability is enabled | `number` | `3` | no |
| create\_namespace | create the namespace resource or not | `bool` | `true` | no |
| enable\_web\_ingress | enable the ingress object for the web component | `bool` | `false` | no |
| external\_identity\_issuer | Use true in Production! If left to false, it will use the certificates coming with this module. For more information: https://linkerd.io/2/tasks/automatically-rotating-control-plane-tls-credentials/ | `bool` | `false` | no |
| grafana\_replicas | number of replicas for grafana component | `number` | `1` | no |
| high\_availability | Enable high availability | `bool` | `false` | no |
| module\_depends\_on | Variable to pass dependancy on external module | `any` | `null` | no |
| namespace\_name | name of the namespace | `string` | `"linkerd"` | no |
| prometheus\_replicas | number of replicas for prometheus component | `number` | `1` | no |
| proxy\_image | docker image name for the proxy | `string` | `"gcr.io/linkerd-io/proxy"` | no |
| proxy\_image\_tag | docker image tag for the proxy | `string` | `"stable-2.8.1"` | no |
| proxy\_init\_image | docker image name for the proxy\_init | `string` | `"gcr.io/linkerd-io/proxy-init"` | no |
| proxy\_init\_image\_tag | docker image tag for the proxy\_init | `string` | `"v1.3.3"` | no |
| proxy\_injector\_pem | custom proxy injector pem file. See example file in certs folder on how to pass it as string | `string` | `""` | no |
| sp\_validator\_pem | custom sp validator pem file. See example file in certs folder on how to pass it as string | `string` | `""` | no |
| trust\_anchors\_pem\_value | PEM value used as trust anchors | `string` | `""` | no |
| trust\_domain | trust domain for TLS certificates | `string` | `"cluster.local"` | no |
| web\_ingress\_annotations | eventual ingress annotations for the ingress-controller | `map(string)` | `{}` | no |
| web\_ingress\_host | host name for the web component | `string` | `""` | no |
| web\_replicas | number of replicas for web component | `number` | `1` | no |

## Outputs

No output.

