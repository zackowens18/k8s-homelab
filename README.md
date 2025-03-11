# k8s-homelab

## What this repo does

This repo is all of the giops for my internal kubernetes home lab using talos linux. This repo is consumed by Flux CD to install/upgrade Flux and all other dependencies for my cluster.

## Pre requisites

- A valid kubeconfig to setup a cluster on this
- A github token

## Bootstrapping

Everything in the /clusters/* is auto generated using the bootsrapping below. By changing the cluster that is specified in the kubeconfig and the path, more clusters can be added to this git repo. Below is an example command that I used to create firmzcluster:
```flux bootstrap github --token-auth --owner=zackowens18 --repository=k8s-homelab-gitops-systems --branch=main --path=clusters/firmzcluster --personal --kubeconfig C:\Users\Firmz\.kubeconfig```

## Layout

## Services

TO DO

### Ingress

### Egress

### Observibility

### Shared Storage

Not needed until more nodes are spun up.