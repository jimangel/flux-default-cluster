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
BASE_FOLDER="base/dex"
CLUSTER_FOLDER=${1:-cluster-kustomize}

mkdir -p ${CLUSTER_FOLDER}/dex-unique


cat <<EOF >${CLUSTER_FOLDER}/dex-unique/kustomization.yaml
namespace: kube-system
bases:
  - ../../base/dex/
#images:
#  - name: quay.io/kubernetes-ingress-controller/nginx-ingress-controller
#    newName: quay.io/jimangel/nginx-ingress-controller
#    newTag: 0.26.1-patched
EOF

mkdir -p ${BASE_FOLDER}

# if stable repo isn't there, add it.
helm repo list | grep -i stable >/dev/null && echo "stable present" || helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
helm template dex-helm stable/dex \
--output-dir ${BASE_FOLDER}

cp ${BASE_FOLDER}/dex/templates/*.yaml ${BASE_FOLDER}/
rm -rf ${BASE_FOLDER}/dex

# TIP: ls cluster-kustomize/common/nginx-ingress/ -lah | awk '{print "  - "$9}' | grep -v kustom* | grep .*.yaml
cat <<EOF >${BASE_FOLDER}/kustomization.yaml
resources:
  - clusterrolebinding.yaml
  - clusterrole.yaml
  - config-openssl.yaml
  - deployment.yaml
  - rolebinding.yaml
  - role.yaml
  - secret.yaml
  - serviceaccount.yaml
  - service.yaml
EOF

for file in $(ls ${BASE_FOLDER}/ | grep -v kustomization.yaml | grep yaml); do kubeval ${BASE_FOLDER}/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done

echo "last updated by $0 on $(date +%F)" > ${CLUSTER_FOLDER}/readme.md
echo "last updated by $0 on $(date +%F)" > ${BASE_FOLDER}/readme.md
