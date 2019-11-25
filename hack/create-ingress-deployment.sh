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

mkdir -p cluster/nginx-ingress-default
mkdir -p cluster/base

cat <<EOF >cluster/kustomization.yaml
bases:
  - ./common/
  - ./nginx-ingress-default/
EOF


cat <<EOF >cluster/nginx-ingress-default/kustomization.yaml
namespace: nginx-ingress
resources:
  - ingress-deployment.yaml
EOF

cat <<EOF >cluster/nginx-ingress-default/flux-patch.yaml
metadata:
  namespace: nginx-ingress
EOF

# use helm v3 to generate template and drop clusterIP (due to https://github.com/kubernetes/ingress-nginx/issues/1612)
helm template ingress-helm stable/nginx-ingress \
--set rbac.create=true \
--set controller.replicaCount="3" \
--set controller.service.type="NodePort" \
--set controller.service.nodePorts.http="30080" \
--set controller.service.nodePorts.https="30443" | grep -v  clusterIP > cluster/base/ingress-deployment.yaml

kubeval cluster/base/ingress-deployment.yaml || echo "failed" && exit 1
