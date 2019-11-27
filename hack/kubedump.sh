#!/usr/bin/env bash

set -e

CONTEXT="$(kubectl config current-context)"

if [[ -z ${CONTEXT} ]]; then
  echo "Usage: $0 KUBE-CONTEXT"
  exit 1
fi

NAMESPACES=$(kubectl --context ${CONTEXT} get -o json namespaces|jq '.items[].metadata.name'|sed "s/\"//g")
RESOURCES="configmap secret daemonset deployment service hpa"

for ns in ${NAMESPACES};do
  for resource in ${RESOURCES};do
    rsrcs=$(kubectl --context ${CONTEXT} -n ${ns} get -o json ${resource}|jq '.items[].metadata.name'|sed "s/\"//g")
    for r in ${rsrcs};do
      #dir="${CONTEXT}/${ns}/${resource}"
      #mkdir -p "${dir}"
      kubectl --context ${CONTEXT} -n ${ns} get -o yaml ${resource} ${r}
    done
  done
done