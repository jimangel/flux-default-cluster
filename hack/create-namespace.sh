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
set -o pipefail

NAMESPACE_FOLDER="base/namespaces"
NAMESPACE=${1}

if [[ -z "$1" ]]; then
    echo "Must provide NAME of namespace" 1>&2
    exit 1
fi

mkdir -p ${NAMESPACE_FOLDER}

kubectl create ns "${NAMESPACE}" -o yaml --dry-run > ${NAMESPACE_FOLDER}/"${NAMESPACE}"-ns.yaml

# add resources folder
rm -rf ${NAMESPACE_FOLDER}/kustomization.yaml
bash hack/generate-kustomize-resources.sh ${NAMESPACE_FOLDER}

echo "last updated by $0 on $(date +%F)" > ${NAMESPACE_FOLDER}/readme.md