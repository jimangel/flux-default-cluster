#!/usr/bin/env bash
# create namespaces
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW
# run: bash ./hack/create-namespace.sh <NAME_SPACE>
# example: bash ./hack/create-namespace.sh flux-system
#
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# =======================================================

set -o errexit
set -o nounset
set -o pipefail

mkdir -p base/namespaces
kubectl create ns "${1}" -o yaml --dry-run > base/namespaces/"${1}".yaml
