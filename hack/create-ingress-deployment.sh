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

# user argument, if not present default to jimangel

mkdir -p cluster/nginx-ingress

cat <<EOF >cluster/nginx-ingress/kustomization.yaml
resources:
- ingress-deployment.yaml
namespace: nginx-ingress
EOF

helm template ingress-helm stable/nginx-ingress \
--set rbac.create=true \
--set controller.replicaCount="3" \
--set controller.service.type="NodePort" \
--set controller.service.nodePorts.http="30080" \
--set controller.service.nodePorts.https="30443" > cluster/nginx-ingress/ingress-deployment.yaml

kubeval cluster/nginx-ingress/ingress-deployment.yaml || echo "failed" && exit 1
