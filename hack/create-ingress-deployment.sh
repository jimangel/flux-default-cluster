#!/usr/bin/env bash
# create namespaces
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW
# run: bash ./hack/create-flux-deployment.sh <GITHUB_USER>
# example: bash ./hack/create-flux-deployment.sh joeschmoe
#
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# =======================================================

set -o errexit
set -o nounset
set -o pipefail

mkdir -p cluster/nginx-ingress-default
mkdir -p cluster/common/nginx-ingress

# TIP: ls cluster/common/nginx-ingress/ -lah | awk '{print "  - "$9}' | grep -v kustom* | grep .*.yaml
cat <<EOF >cluster/common/nginx-ingress/kustomization.yaml
resources:
  - clusterrolebinding.yaml
  - clusterrole.yaml
  - controller-deployment.yaml
  - controller-poddisruptionbudget.yaml
  - controller-rolebinding.yaml
  - controller-role.yaml
  - controller-serviceaccount.yaml
  - controller-service.yaml
  - default-backend-deployment.yaml
  - default-backend-serviceaccount.yaml
  - default-backend-service.yaml
EOF


cat <<EOF >cluster/kustomization.yaml
bases:
  - ./common/namespaces/
  - ./nginx-ingress-default/
EOF


cat <<EOF >cluster/nginx-ingress-default/kustomization.yaml
namespace: nginx-ingress
bases:
  - ../common/nginx-ingress/
EOF

# use helm v3 to generate template and drop clusterIP (due to https://github.com/kubernetes/ingress-nginx/issues/1612)
kubectl config set-context --current --namespace=nginx-ingress
helm template ingress-helm stable/nginx-ingress \
--set rbac.create=true \
--set controller.replicaCount="3" \
--set controller.service.type="NodePort" \
--set controller.service.nodePorts.http="30080" \
--set controller.service.nodePorts.https="30443" \
--output-dir cluster/common/nginx-ingress

cp cluster/common/nginx-ingress/nginx-ingress/templates/*.yaml cluster/common/nginx-ingress/
rm -rf cluster/common/nginx-ingress/nginx-ingress

# from ClusterIP causing issues on baremetal
sed -i '/ClusterIP/d' $(grep -rl ClusterIP cluster/common/nginx-ingress/)

for file in $(ls cluster/common/nginx-ingress/ | grep -v kustomization.yaml); do kubeval cluster/common/nginx-ingress/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done
