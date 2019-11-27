#!/usr/bin/env bash
# create namespaces
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW
#
# bash hack/BUILD_CORE_REPO.sh <OPTIONAL CLUSTER NAME>
#
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# TODO: SCALE OUT TO MORE CLUSTERS, GET 1 CLUSTER PERFECT
# THEN CREATE CLUSTER-XYZ-2
# =======================================================

set -o errexit
set -o nounset
set -o pipefail

CLUSTER_FOLDER=${1:-cluster-kustomize} # default to cluster-kustomize if not set

# create or validate "core" folders
mkdir -p install                              # flux and cni (manual)
mkdir -p base                                 # shared "generated" base yaml
mkdir -p ${CLUSTER_FOLDER} # cluster folder for custom yaml
# could split cluster folder into 2 folders (dev / prod, or location A and location B)

# drop the idea of static and put in kustomize folder???

# create a readme with update time
echo "last updated by $0 on $(date +%F), (re)creating ${CLUSTER_FOLDER}" > install/readme.md
echo "last updated by $0 on $(date +%F), (re)creating ${CLUSTER_FOLDER}" > base/readme.md
echo "last updated by $0 on $(date +%F)" > ${CLUSTER_FOLDER}/readme.md

cat <<EOF >${CLUSTER_FOLDER}/kustomization.yaml
bases:
  - ../base/namespaces/
  - ./nginx-ingress-unique/
#  - ./harbor-unique/
# wip - ./dashboard2/
# wip - ./gangway-unique/
# wip - ./minio/
# wip - ./rook/
# wip - ./istio/
# wip - ./consul-server/
# wip - ./consul-client/
# wip - ./consul-connect-servicemesh/
# wip - ./vault/
# wip - ./elk/
#  - ./gatekeeper-unique/
#  - ./dex-unique/
#  - ./prometheus-unique/
EOF

# this is needed to tell flux how to dela with the cluster folder (kustomize)
cat <<EOF >${CLUSTER_FOLDER}/.flux.yaml
version: 1
commandUpdated:
  generators:
    - command: kustomize build .
EOF
