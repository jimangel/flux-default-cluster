#!/usr/bin/env bash
# create namespaces
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW
# run: bash ./hack/create-flux-deployment.sh <GITHUB_USER>
# example: bash ./hack/create-flux-deployment.sh joeschmoe
#
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# =======================================================


#################
#################
#
# WIP!!
#
#################
#################

set -o errexit
set -o nounset
set -o pipefail

BASE_REPO="base/canal"
KUSTOMIZE_REPO="install/cni"

mkdir -p install/cni
mkdir -p base/canal

curl -Lo base/canal/canal.yaml https://docs.projectcalico.org/v3.10/manifests/canal.yaml

# TIP: ls cluster-kustomize/common/nginx-ingress/ -lah | awk '{print "  - "$9}' | grep -v kustom* | grep .*.yaml
cat <<EOF >${BASE_REPO}/kustomization.yaml
resources:
  - canal.yaml
EOF

# create the patch that updates Calico's PV4 POOL
cat <<EOF >${KUSTOMIZE_REPO}/pod-cidr-patch.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: canal
spec:
  template:
    spec:
      containers:
        - name: calico-node
          env:
            - name: CALICO_IPV4POOL_CIDR
              value: "10.244.0.0/16"
EOF

cat <<EOF >${KUSTOMIZE_REPO}/kustomization.yaml
patchesStrategicMerge:
  - pod-cidr-patch.yaml
bases:
  - ../../base/canal/
images:
  - name: quay.io/coreos/flannel
    newName: quay.io/coreos/flannel-git
    newTag: v0.11.0-59-g960b324
  - name: calico/pod2daemon-flexvol
    newName: quay.io/jimangel/pod2daemon-flexvol
    newTag: v3.10.2-patched
EOF

for file in $(ls ${BASE_REPO} | grep -v kustomization.yaml | grep yaml); do kubeval --ignore-missing-schemas ${BASE_REPO}/${file} || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done

echo "last updated by $0 on $(date +%F)" > ${BASE_REPO}/readme.md
echo "last updated by $0 on $(date +%F)" > ${KUSTOMIZE_REPO}/readme.md