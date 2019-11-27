#!/usr/bin/env bash
# create namespaces
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW
# run: bash ./hack/create-flux-deployment.sh <GITHUB_USER>
# example: bash ./hack/create-flux-deployment.sh joeschmoe
# example: bash ./hack/create-consul-client-deplyoment
#
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# =======================================================

## BEFORE RUNNING, SET ENV VARS
# export CONSUL_TOKEN="1234-1234-1234-1234"

set -o errexit
set -o pipefail

BASE_FOLDER="base/consul-client"
CLUSTER_FOLDER="${1:-cluster-kustomize}/consul-client-unique"

DC_NAME="{$2:-dcname}"

# clean up
rm -rf ${BASE_FOLDER}
rm -rf ${CLUSTER_FOLDER}

mkdir -p ${BASE_FOLDER}
mkdir -p ${CLUSTER_FOLDER}

cat <<EOF >${CLUSTER_FOLDER}/extra-config.yaml
# Source: consul/templates/client-config-configmap.yaml
# ConfigMap with extra configuration specified directly to the chart
# for client agents only.
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-name-consul-client-config
  namespace: default
  labels:
    app: consul
    chart: consul-helm
    heritage: Tiller
    release: release-name
data:
  extra-from-values.json: |-
    {
      "log_level": "DEBUG",
      "ports": {
        "serf_lan": 8311,
        "http": 8511
      },
      "acl": {
        "enabled": true,
        "default_policy": "deny",
        "enable_token_persistence": false,
        "tokens": {
          "default": "${CONSUL_TOKEN:-1234-1234-1234-1234}"
        }
      }
    }
EOF

cat <<EOF >${CLUSTER_FOLDER}/kustomization.yaml
namespace: default
resources:
  - ./extra-config.yaml
  # TODO: NEED TO CREATE THE TOKEN FILE
bases:
  - ../../${BASE_FOLDER}
#images:
#  - name: consul
#    newName: consul
#    newTag: 1.6.2
#  - name: hashicorp/consul-k8s
#    newName: hashicorp/consul-k8s
#    newTag: 0.9.5
EOF

curl -LO https://github.com/hashicorp/consul-helm/archive/master.zip
unzip master.zip

helm template consul-helm ./consul-helm-master \
--set global.enabled=true \
--set global.domian=consul \
--set datacenter="${DC_NAME}" \
--set enablePodSecurityPolicies="false" \
--set gossipEncryption.secretName="" \
--set gossipEncryption.secretKey="" \
--set bootstrapACLs="false" \
--set server.enabled="false" \
--set client.enabled="true" \
--set client.join[0]="127.0.0.1" \
--set client.snapshotAgent.enabled="false" \
--set ui.enabled="false" \
--set syncCatalog.enabled="true" \
--set meshGateway.enabled="false" \
--set dns.enabled="false" \
--set connectIngject="false" 

# --output-dir ${BASE_FOLDER}

cp ${BASE_FOLDER}/nginx-ingress/templates/*.yaml ${BASE_FOLDER}/
rm -rf ${BASE_FOLDER}/nginx-ingress



# from ClusterIP causing issues on baremetal
for YAML in $(grep -rl clusterIP ${BASE_FOLDER}); do sed -i '/clusterIP/d' $YAML; done

# create updated resources
bash hack/generate-kustomize-resources.sh ${BASE_FOLDER}

for file in $(ls ${BASE_FOLDER} | grep -v kustomization.yaml | grep yaml); do kubeval ${BASE_FOLDER}/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done

echo "last updated by $0 on $(date +%F)" > ${CLUSTER_FOLDER}/readme.md
echo "last updated by $0 on $(date +%F)" > ${BASE_FOLDER}/readme.md