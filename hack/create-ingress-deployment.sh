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

BASE_FOLDER="base/nginx-ingress"
CLUSTER_FOLDER="${1:-cluster-kustomize}/nginx-ingress-unique"

# clean up
rm -rf ${BASE_FOLDER}
rm -rf ${CLUSTER_FOLDER}

mkdir -p ${BASE_FOLDER}
mkdir -p ${CLUSTER_FOLDER}

# add customization test
cat <<EOF >${CLUSTER_FOLDER}/config-map.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: ingress-helm-nginx-ingress-controller
  namespace: nginx-ingress
data:
  enable-underscores-in-headers: "true"
EOF



cat << 'EOF' >${CLUSTER_FOLDER}/controller-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingress-helm-nginx-ingress-controller
spec:
  template:
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/ingress"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
        - name: nginx-ingress-controller
          args:
            - /nginx-ingress-controller
            - --default-backend-service=$(POD_NAMESPACE)/ingress-helm-nginx-ingress-default-backend
            - --election-id=ingress-controller-leader
            - --ingress-class=nginx
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --annotations-prefix=nginx.ingress.kubernetes.io
            - --default-ssl-certificate=ingress-nginx/default-ingress-ssl
      nodeSelector:
        node-role.kubernetes.io/ingress: ""
EOF

cat << 'EOF' >${CLUSTER_FOLDER}/backend-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingress-helm-nginx-ingress-default-backend
spec:
  template:
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/ingress"
        operator: "Exists"
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/ingress: ""
EOF

# since we create the base manifest with helm, the default PSP binds a different service account. This could alternatly be solved on Helm's end.
cat <<EOF >${CLUSTER_FOLDER}/extra-psp-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ingress-nginx-psp-actual
  namespace: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-nginx-psp
subjects:
- kind: ServiceAccount
  name: ingress-helm-nginx-ingress
EOF

cat <<EOF >${CLUSTER_FOLDER}/kustomization.yaml
namespace: nginx-ingress
resources:
  - config-map.yaml
  - extra-psp-binding.yaml
bases:
  - ../../${BASE_FOLDER}
images:
  - name: quay.io/kubernetes-ingress-controller/nginx-ingress-controller
    newName: quay.io/jimangel/nginx-ingress-controller
    newTag: 0.26.1-patched
patchesStrategicMerge:
  - controller-patch.yaml
  - backend-patch.yaml
EOF

# use helm v3 to generate template and drop clusterIP (due to https://github.com/kubernetes/ingress-nginx/issues/1612)
#kubectl config set-context --current --namespace=nginx-ingress

helm template ingress-helm stable/nginx-ingress \
--set rbac.create=true \
--set controller.service.type="NodePort" \
--set controller.service.nodePorts.http="30080" \
--set controller.service.nodePorts.https="30443" \
--set controller.replicaCount="3" \
--output-dir ${BASE_FOLDER}

#--set controller.service.externalTrafficPolicy="Local" \
#--set defaultBackend.nodeSelector.node-role\\.kubernetes\\.io/ingress="" \
#--set controller.nodeSelector.node-role\\.kubernetes\\.io/ingress="" \
#--set controller.tolerations[0].key="node-role.kubernetes.io/ingress" \
#--set controller.tolerations[0].operator="Equal" \
#--set controller.tolerations[0].effect="NoSchedule" \
#--set defaultBackend.tolerations[0].key="node-role.kubernetes.io/ingress" \
#--set defaultBackend.tolerations[0].operator="Equal" \
#--set defaultBackend.tolerations[0].effect="NoSchedule" \

cp ${BASE_FOLDER}/nginx-ingress/templates/*.yaml ${BASE_FOLDER}/
rm -rf ${BASE_FOLDER}/nginx-ingress


# add in PSPs
curl -Lo ${BASE_FOLDER}/psp.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/docs/examples/psp/psp.yaml

# from ClusterIP causing issues on baremetal
for YAML in $(grep -rl clusterIP ${BASE_FOLDER}); do sed -i '/clusterIP/d' $YAML; done

# create updated resources
bash hack/generate-kustomize-resources.sh ${BASE_FOLDER}

for file in $(ls ${BASE_FOLDER} | grep -v kustomization.yaml | grep yaml); do kubeval ${BASE_FOLDER}/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done

echo "last updated by $0 on $(date +%F)" > ${CLUSTER_FOLDER}/readme.md
echo "last updated by $0 on $(date +%F)" > ${BASE_FOLDER}/readme.md
