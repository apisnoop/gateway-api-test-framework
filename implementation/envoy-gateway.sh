#!/usr/bin/env bash


deploy::envoy-gateway() {
  echo "deploy::envoy-gateway"

  helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.0.1 -n envoy-gateway-system --create-namespace
  kubectl -n envoy-gateway-system wait --for=condition=Ready --selector="control-plane=envoy-gateway" --timeout=120s pod

  kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/main/examples/kubernetes/quickstart.yaml
  sleep 20
  kubectl -n envoy-gateway-system wait --for=condition=Ready --selector="app.kubernetes.io/name=envoy" --timeout=120s pod
}
