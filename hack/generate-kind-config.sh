#!/usr/bin/env bash

set -o errexit
set -o pipefail


cat <<EOF > kind-config.yaml
# last updated by $0 on $(date +%F)
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# patch the generated kubeadm config with some extra settings
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    extraArgs:
      runtime-config: "apps/v1beta1=false,apps/v1beta2=false,extensions/v1beta1/daemonsets=false,extensions/v1beta1/deployments=false,extensions/v1beta1/replicasets=false,extensions/v1beta1/networkpolicies=false,extensions/v1beta1/podsecuritypolicies=false"
# 3 control plane node and 6 workers
nodes:
# the three HA control plane node config
- role: control-plane
- role: control-plane
- role: control-plane

# the three "ingress" workers
- role: worker
  kubeadmConfigPatches:
  - |
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress=true"
- role: worker
  kubeadmConfigPatches:
  - |
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress=true"
- role: worker
  kubeadmConfigPatches:
  - |
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress=true"

# the three workers
- role: worker
- role: worker
- role: worker

# setup more production-like networking
networking:
  # default 10.0.0.0/16 CIDR used for services VIPs, matching flannel
  serviceSubnet: 10.96.0.0/12
  # PodSubnet is the CIDR used for pod IPs
  podSubnet: 10.244.0.0/16
 
  # turn off CNI to allow canal install
  disableDefaultCNI: true
EOF