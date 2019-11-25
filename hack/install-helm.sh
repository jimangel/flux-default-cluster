#!/usr/bin/env bash
# download kubeeval
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW
# run: sudo bash ./hack/download-kubeeval.sh
#
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# =======================================================

set -o errexit
set -o nounset
set -o pipefail

HELM=$(which helm || echo "/usr/bin/helm")
curl -O https://get.helm.sh/helm-v3.0.0-linux-amd64.tar.gz
tar -zxvf helm-v3.0.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm "${HELM}"
chmod +x "${HELM}"

helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update


# clean up
for i in $(tar tf helm-v3.0.0-linux-amd64.tar.gz); do `rm -rf $i`; done

rm -rf helm-v3.0.0-linux-amd64.tar.gz
