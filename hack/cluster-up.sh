#!/usr/bin/env bash
# Create a kustomization.yaml and then add all kubernetes YAMLs into resources...
set -o errexit
set -o nounset
set -o pipefail

# TODO: add a check for fluxctl command


echo "Creating Cluster.."
kind create cluster --image=kindest/node:v1.15.6@sha256:18c4ab6b61c991c249d29df778e651f443ac4bcd4e6bdd37e0c83c0d33eaae78 --config kind-config.yaml

echo "Creating CNI"
kubectl config set-context kind-kind
kubectl apply -k install/cni/

# wait for canal to come up
kubectl -n kube-system rollout status daemonset/canal

echo "Applying Labels"
for ingress in $(kubectl get nodes -l ingress=true -o custom-columns=':metadata.name'); do kubectl label node $ingress node-role.kubernetes.io/ingress= && kubectl taint node $ingress node-role.kubernetes.io/ingress=:NoSchedule; done

for worker in $(kubectl get nodes -o wide | grep -v "master\|ingress" | awk '{if (NR!=1) {print $1}}'); do kubectl label node $worker node-role.kubernetes.io/worker=; done

echo "Installing Flux"
kubectl create ns flux-system
kubectl apply -k install/flux/

kubectl -n flux-system rollout status deployment/flux

echo "Your flux's identity:"

fluxctl identity --k8s-fwd-ns flux-system

echo "Complete!"

