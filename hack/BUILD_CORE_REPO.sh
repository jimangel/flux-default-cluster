#!/usr/bin/env bash
# create namespaces
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW

# need examples

#
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# =======================================================

set -o errexit
set -o nounset
set -o pipefail

mkdir -p install

cat <<EOF >install/kustomization.yaml
namespace: flux-system
bases:
  - ../base/flux/
patchesStrategicMerge:
  - flux-patch.yaml
EOF


mkdir -p cluster

cat <<EOF >cluster/.flux.yaml
version: 1
commandUpdated:
  generators:
    - command: kustomize build .
EOF

