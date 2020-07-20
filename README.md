# Linkerd2 Terraform Module (WIP)

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

To run a terraform plan you can perform the following:

- Run a simple tf plan
```bash
terraform plan
```

- Run tf plan and save in tfplan file
```bash
terraform plan -out=terraform.tfplan
```

- In cases where you want to inspect the output of the plan
```bash
terraform plan -out=terraform.tfplan && \
terraform show -json terraform.tfplan > plan.json
```

### High Availability Mode
There is a boolean variable `high_availability` that needs to be set, to switch on high availability in the cluster, this controls when to apply various pod/node affinities defined in the linkerd deployments.

## Apply

## Observability

### Prometheus

### Grafana

## Gotchas