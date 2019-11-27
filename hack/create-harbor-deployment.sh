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

BASE_FOLDER="base/harbor"
CLUSTER_FOLDER="${1:-cluster-kustomize}/harbor-unique"
NAMESPACE="harbor"

mkdir -p ${BASE_FOLDER}
mkdir -p ${CLUSTER_FOLDER}

# don't forget: bash hack/create-namespace.sh harbor
cat <<EOF >${CLUSTER_FOLDER}/kustomization.yaml
namespace: ${NAMESPACE}
bases:
  - ../../${BASE_FOLDER}
#images:
#  - name: quay.io/kubernetes-ingress/
#    newName: quay.io/jimangel/nginx-ingress-controller
#    newTag: 0.26.1-patched
EOF

# use helm v3 to generate template
kubectl config set-context --current --namespace=${NAMESPACE}
helm repo add harbor https://helm.goharbor.io
helm template harbor-helm harbor/harbor \
--set persistence.enabled=false \
--set chartmuseum.enabled=false \
--set notary.enabled=false \
--output-dir ${BASE_FOLDER}

cp -rf ${BASE_FOLDER}/harbor/templates/* ${BASE_FOLDER}/
rm -rf ${BASE_FOLDER}/harbor

# add resources folder
rm -rf ${BASE_FOLDER}/kustomization.yaml
bash hack/generate-kustomize-resources.sh ${BASE_FOLDER}

for file in $(find ${BASE_FOLDER} -type f -name "*.yaml" -printf './%P\n' | grep -v kustomization.yaml); do kubeval ${BASE_FOLDER}/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done

echo "last updated by $0 on $(date +%F)" > ${CLUSTER_FOLDER}/readme.md
echo "last updated by $0 on $(date +%F)" > ${BASE_FOLDER}/readme.md