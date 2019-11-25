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

cat <<EOF >.flux.yml
version: 1
commandUpdated:
  generators:
    - command: kustomize build 
EOF

mkdir -p cluster

cat <<EOF >cluster/kustomization.yaml
bases:
  - ./nginx-ingress/
  - ./common/
EOF
