 ls cluster-kustomize/common/kube-prometheus/ -lah | awk '{print "  - "$9}' | grep -v kustom* | grep .*.yaml#!/usr/bin/env bash
# create namespaces
# =======================================================
# RUN IN THE BASE DIRECTORY EXACTLY LIKE BELOW
# TODO: add (T / F) auto-commit to master branch (Y /N?)
# =======================================================

set -o errexit
set -o nounset
set -o pipefail


mkdir -p cluster-kustomize/prometheus
mkdir -p cluster-kustomize/common/kube-prometheus

# this is needed becuase we have to split up the CRDs and manifests
#mkdir -p cluster-static/prometheus

curl -LO https://github.com/coreos/kube-prometheus/archive/master.zip
unzip master.zip

rsync -avh kube-prometheus-master/manifests/ cluster-kustomize/common/kube-prometheus/

mv cluster-kustomize/common/kube-prometheus/setup/*.yaml cluster-kustomize/common/kube-prometheus/

# splitting out CRDs
# rsync -avh cluster-kustomize/common/kube-prometheus/setup/ cluster-static/prometheus/

# delete namespace (since already created)
# TODO: turn to if exists...
#rm cluster-static/prometheus/0namespace-namespace.yaml

rm  cluster-kustomize/common/kube-prometheus/0namespace-namespace.yaml

# clean up kustomize folder
rm -rf cluster-kustomize/common/kube-prometheus/setup

# SETUP KUSTOMIZE  RESOURCES
# TIP: ls cluster-kustomize/common/kube-prometheus/ -lah | awk '{print "  - "$9}' | grep -v kustom* | grep .*.yaml
cat <<EOF >cluster-kustomize/common/kube-prometheus/kustomization.yaml
resources:
  - alertmanager-alertmanager.yaml
  - alertmanager-secret.yaml
  - alertmanager-serviceAccount.yaml
  - alertmanager-serviceMonitor.yaml
  - alertmanager-service.yaml
  - grafana-dashboardDatasources.yaml
  - grafana-dashboardDefinitions.yaml
  - grafana-dashboardSources.yaml
  - grafana-deployment.yaml
  - grafana-serviceAccount.yaml
  - grafana-serviceMonitor.yaml
  - grafana-service.yaml
  - kube-state-metrics-clusterRoleBinding.yaml
  - kube-state-metrics-clusterRole.yaml
  - kube-state-metrics-deployment.yaml
  - kube-state-metrics-roleBinding.yaml
  - kube-state-metrics-role.yaml
  - kube-state-metrics-serviceAccount.yaml
  - kube-state-metrics-serviceMonitor.yaml
  - kube-state-metrics-service.yaml
  - node-exporter-clusterRoleBinding.yaml
  - node-exporter-clusterRole.yaml
  - node-exporter-daemonset.yaml
  - node-exporter-serviceAccount.yaml
  - node-exporter-serviceMonitor.yaml
  - node-exporter-service.yaml
  - prometheus-adapter-apiService.yaml
  - prometheus-adapter-clusterRoleAggregatedMetricsReader.yaml
  - prometheus-adapter-clusterRoleBindingDelegator.yaml
  - prometheus-adapter-clusterRoleBinding.yaml
  - prometheus-adapter-clusterRoleServerResources.yaml
  - prometheus-adapter-clusterRole.yaml
  - prometheus-adapter-configMap.yaml
  - prometheus-adapter-deployment.yaml
  - prometheus-adapter-roleBindingAuthReader.yaml
  - prometheus-adapter-serviceAccount.yaml
  - prometheus-adapter-service.yaml
  - prometheus-clusterRoleBinding.yaml
  - prometheus-clusterRole.yaml
  - prometheus-operator-0alertmanagerCustomResourceDefinition.yaml
  - prometheus-operator-0podmonitorCustomResourceDefinition.yaml
  - prometheus-operator-0prometheusCustomResourceDefinition.yaml
  - prometheus-operator-0prometheusruleCustomResourceDefinition.yaml
  - prometheus-operator-0servicemonitorCustomResourceDefinition.yaml
  - prometheus-operator-clusterRoleBinding.yaml
  - prometheus-operator-clusterRole.yaml
  - prometheus-operator-deployment.yaml
  - prometheus-operator-serviceAccount.yaml
  - prometheus-operator-serviceMonitor.yaml
  - prometheus-operator-service.yaml
  - prometheus-prometheus.yaml
  - prometheus-roleBindingConfig.yaml
  - prometheus-roleBindingSpecificNamespaces.yaml
  - prometheus-roleConfig.yaml
  - prometheus-roleSpecificNamespaces.yaml
  - prometheus-rules.yaml
  - prometheus-serviceAccount.yaml
  - prometheus-serviceMonitorApiserver.yaml
  - prometheus-serviceMonitorCoreDNS.yaml
  - prometheus-serviceMonitorKubeControllerManager.yaml
  - prometheus-serviceMonitorKubelet.yaml
  - prometheus-serviceMonitorKubeScheduler.yaml
  - prometheus-serviceMonitor.yaml
  - prometheus-service.yaml
EOF


# SETUP  BASE (folder / callout namespace)
cat <<EOF >cluster-kustomize/prometheus/kustomization.yaml
bases:
  - ../common/kube-prometheus/
EOF



# clean up
rm -rf master.zip
rm -rf kube-prometheus-master

#for file in $(ls cluster-static/prometheus/); do kubeval --ignore-missing-schemas cluster-static/prometheus/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done


for file in $(ls cluster-kustomize/common/kube-prometheus | grep -v kustomization.yaml); do kubeval --ignore-missing-schemas cluster-kustomize/common/kube-prometheus/"${file}" || if [[ $? -eq 1 ]]; then echo "failed" && exit 1; fi; done
