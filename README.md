# Linkerd2 Terraform Module

Terraform module to deploy Linkerd2 on Kubernetes

terraform init
terraform plan
terraform apply

## Features 

## Deployment

## Prerequisites

Install the following on your mac:
- Brew
- Docker
- Kubernetest (with a local cluster running)

## Setup

### Setting up Linkerd Locally

Run the following commands to ensure that your local copy of linkerd is properly setup:

- Install linkerd using brew and check the version
```bash
brew install linkerd
linkerd version
```

- Run linkerd install and apply to your local kubernetes cluster and run a check or inspect the components deployed
```bash
linkerd install --linkerd-cni-enabled | kubectl apply -f -
linkerd check
kubectl -n linkerd get deploy
```

- If you have issues with your linkerd config/control-plane resources missing, run and check if it is installed
```bash
linkerd install config | kubectl apply -f -
linkerd check config
linkerd install control-plane | kubectl apply -f -
linkerd check
```

-- If you want to re-install linkerd, overwriting previous configurations:
```bash
linkerd install --linkerd-cni-enabled --ignore-cluster | kubectl apply -f -
linkerd check
```

-- Remove all linkerd resources
```bash
linkerd uninstall | kubectl delete -f -
```

## Plan

## Apply

## Observability

### Prometheus

### Grafana

## Gotchas