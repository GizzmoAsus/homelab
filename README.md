# Homelab Setup and Configuration

TBD

## Terraform

Leverages the proxmox provider to spin up a number fo services on the homelab cluster:

* NFS Server - Primary storage for the kubernetes pvc hosting
* Kubernetes:
  * control-plane: primary master node that serves the main kubernetes-api
  * worker-cpu: primary workload nodes that leverage CPU for compute
  * worker-gpu: primary workload nodes that expose GPU capabilities

This will grow over time as new services are migrated into this new cluster e.g. pihole

## Ansible

run...

## Manual Steps

1. Label kube nodes (will add to playbook later)
2. Set up and configure metallb as per https://metallb.io/installation/
