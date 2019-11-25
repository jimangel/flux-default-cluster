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

fluxctl install \
--git-user=${GHUSER} \
--git-email=${GHUSER}@users.noreply.github.com \
--git-url=git@github.com:${GHUSER}/flux-default-cluster \
--git-path=cluster \
--namespace=flux-system > base/flux/flux-in-a-box.yaml

for file in $(ls base/flux); do kubeval base/flux/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done
