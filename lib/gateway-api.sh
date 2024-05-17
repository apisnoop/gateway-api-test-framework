#!/usr/bin/env bash


deploy::gateway-api() {
  echo "deploy::gateway-api"
  echo "GATEWAY_API_VERSION: ${GATEWAY_API_VERSION}"

  # load gateway crds
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/experimental/gateway.networking.k8s.io_gatewayclasses.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/experimental/gateway.networking.k8s.io_gateways.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/experimental/gateway.networking.k8s.io_httproutes.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/experimental/gateway.networking.k8s.io_referencegrants.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/experimental/gateway.networking.k8s.io_grpcroutes.yaml

  # wait condition 'Established'
  kubectl wait --for condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=${TIMEOUT}
  kubectl wait --for condition=Established crd/gateways.gateway.networking.k8s.io --timeout=${TIMEOUT}
  kubectl wait --for condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=${TIMEOUT}
  kubectl wait --for condition=Established crd/tlsroutes.gateway.networking.k8s.io --timeout=${TIMEOUT}
  kubectl wait --for condition=Established crd/referencegrants.gateway.networking.k8s.io --timeout=${TIMEOUT}
  kubectl wait --for condition=Established crd/grpcroutes.gateway.networking.k8s.io --timeout=${TIMEOUT}
}
