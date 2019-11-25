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
mkdir -p install/

curl -LO https://github.com/fluxcd/flux/archive/master.zip
unzip master.zip

rsync -avh flux-master/deploy/ base/flux/

# drop out namespace
rm -rf base/flux/flux-ns.yaml
sed -i '/flux-ns/d' base/flux/kustomization.yaml

# update patch for flux
cat <<EOF >install/flux-patch.yaml
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
            - --manifest-generation=true
            - --memcached-hostname=flux-memcached.flux-system
            - --memcached-service=
            - --git-poll-interval=5m
            - --sync-interval=5m
            - --ssh-keygen-dir=/var/fluxd/keygen
            - --git-branch=master
            - --git-path=cluster
            - --git-url=git@github.com:${GHUSER}/flux-default-cluster
EOF

rm -rf master.zip
rm -rf flux-master/

#fluxctl install \
#--git-user=${GHUSER} \
#--git-email=${GHUSER}@users.noreply.github.com \
#--git-url=git@github.com:${GHUSER}/flux-default-cluster \
#--git-path=cluster \
#--namespace=flux-system > base/flux/flux-in-a-box.yaml

for file in $(ls base/flux | grep -v kustomization.yaml); do kubeval base/flux/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done
