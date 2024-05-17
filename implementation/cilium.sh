#!/usr/bin/env bash

export KIND_DISABLE_CNI="true"

deploy::cilium() {
  echo "deploy::cilium"

  check_helm_repo_list=$(helm repo list -ojson | jq -c '.[] | select( .name | contains("cilium"))' | jq -c 'select( .url | contains("https://helm.cilium.io/"))')
  if [[ "${#check_helm_repo_list}" -eq 0 ]] ; then
    helm repo add cilium https://helm.cilium.io
  fi
  echo "Checking helm repo list.... ${check_helm_repo_list}"

  helm upgrade --install cilium cilium/cilium --version 1.15.4 --namespace kube-system --set kubeProxyReplacement=strict --set gatewayAPI.enabled=true
}

deploy::cilium::gatewayclass() {
  echo "deploy::cilium::gatewayclass"

  cat << EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: cilium
spec:
  controllerName: io.cilium/gateway-controller
EOF

}
