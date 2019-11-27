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

BASE_FOLDER="base/gatekeeper"
CLUSTER_FOLDER="${1:-cluster-kustomize}/gatekeeper-unique"

mkdir -p ${CLUSTER_FOLDER}

cat <<EOF >${CLUSTER_FOLDER}/kustomization.yaml
namespace: gatekeeper-system
bases:
  - ../../${BASE_FOLDER}
#images:
#  - name: quay.io/custom-image
#    newName: quay.io/jimangel/custom-image
#    newTag: 0.26.1-patched
EOF

mkdir -p ${BASE_FOLDER}

curl -s -o "${BASE_FOLDER}/gatekeeper.yaml" "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml"

# chop out namespace...
sed -i '1,8d' ${BASE_FOLDER}/gatekeeper.yaml

# TIP: ls cluster-kustomize/common/nginx-ingress/ -lah | awk '{print "  - "$9}' | grep -v kustom* | grep .*.yaml
cat <<EOF >${BASE_FOLDER}/kustomization.yaml
resources:
  - gatekeeper.yaml
EOF

for file in $(ls ${BASE_FOLDER} | grep -v kustomization.yaml | grep yaml); do kubeval --ignore-missing-schemas ${BASE_FOLDER}/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done

echo "last updated by $0 on $(date +%F)" > ${CLUSTER_FOLDER}/readme.md
echo "last updated by $0 on $(date +%F)" > ${BASE_FOLDER}/readme.md
