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

curl -Lo ./conftest.tar.gz https://github.com/instrumenta/conftest/releases/download/v0.15.0/conftest_0.15.0_Linux_x86_64.tar.gz
tar xvf conftest.tar.gz

sudo cp conftest /usr/local/bin/conftest
sudo rm -rf conftest
sudo chmod +x /usr/local/bin/conftest

# clean up
for i in $(tar tf conftest.tar.gz); do `rm -rf $i`; done

rm -rf conftest.tar.gz

curl https://raw.githubusercontent.com/naquada/deprek8/master/policy/deprek8.rego > deprek8.rego
