#!/usr/bin/env bash
# Create a kustomization.yaml and then add all kubernetes YAMLs into resources...
set -o errexit
set -o pipefail

# TODO: if $1 isn't set, break, echo "Provide a path to generate a kustomize.html"

if [[ -z "$1" ]]; then
    echo "Must provide DIRECTORY where to run and generate kustomize" 1>&2
    exit 1
fi

KUSTOMIZE_PATH=${1}

if [ ! -f ${KUSTOMIZE_PATH}/kustomization.yaml ]; then
    echo "File not found! Creating..."
echo -n "
resources:
" > ${KUSTOMIZE_PATH}/kustomization.yaml

for file in $(find ${KUSTOMIZE_PATH} -type f -name "*.yaml" -printf './%P\n' | grep -v kustomization.yaml); do
echo "  - ${file}" >> ${KUSTOMIZE_PATH}/kustomization.yaml
done

fi





