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

curl -Lo ./kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar -xvf kubeval.tar.gz

sudo cp kubeval /usr/local/bin/kubeval
sudo rm -rf kubeval
sudo chmod +x /usr/local/bin/kubeval

# clean up
for i in $(tar tf kubeval.tar.gz); do `rm -rf $i`; done

rm -rf kubeval.tar.gz
