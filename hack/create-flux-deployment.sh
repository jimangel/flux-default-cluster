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
GHUSER="${1:-jimangel}"

mkdir -p base/flux
mkdir -p install/flux

curl -LO https://github.com/fluxcd/flux/archive/master.zip
unzip master.zip

rsync -avh flux-master/deploy/ base/flux/

# drop out namespace
rm -rf base/flux/flux-ns.yaml
sed -i '/flux-ns/d' base/flux/kustomization.yaml

# create flux custom tweaks 
cat <<EOF >install/flux/kustomization.yaml
namespace: flux-system
bases:
  - ../../base/flux/
patchesStrategicMerge:
  - flux-patch.yaml
EOF

# update patch for flux
cat <<EOF >install/flux/flux-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flux
spec:
  template:
    spec:
      containers:
        - name: flux
          args:
            - --manifest-generation=true # USED FOR KUSTOMIZE
            - --sync-garbage-collection=true
            - --git-poll-interval=30s
            - --sync-interval=5m
            - --ssh-keygen-dir=/var/fluxd/keygen
            - --git-branch=master
            - --git-path=cluster-kustomize
            - --git-email=${GHUSER}@users.noreply.github.com
            - --git-url=git@github.com:${GHUSER}/flux-default-cluster
EOF

# clean up
rm -rf master.zip
rm -rf flux-master/

for file in $(ls base/flux | grep -v kustomization.yaml | grep yaml); do kubeval base/flux/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done

echo "last updated by $0 on $(date +%F)" > base/flux/readme.md
echo "last updated by $0 on $(date +%F)" > install/flux/readme.md
