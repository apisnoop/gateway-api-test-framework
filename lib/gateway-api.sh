#!/usr/bin/env bash


deploy::gateway-api() {
  if [[ ${IMPLEMENTATION} != "none" ]] ; then
    echo "deploy::gateway-api"
    echo "GATEWAY_API_VERSION: ${GATEWAY_API_VERSION}"
    echo "GATEWAY_API_CHANNEL: ${GATEWAY_API_CHANNEL}"

    case ${GATEWAY_API_CHANNEL} in

      "standard" )
        deploy::gateway-api::standard::${GATEWAY_API_VERSION}
        ;;

      "experimental")
        deploy::gateway-api::experimental::${GATEWAY_API_VERSION}
        ;;

      "none")
        echo "No gateway-api implementation requested."
        ;;

      *)
        echo "Error: GATEWAY_API_CHANNEL unknown, exiting"
        exit 1
        ;;
    esac
  fi
}

deploy::gateway-api::standard::v1.0.0(){
  deploy::gateway-api::base-crds
}

deploy::gateway-api::experimental::v1.0.0(){
  deploy::gateway-api::base-crds
  deploy::gateway-api::grpcroutes
  deploy::gateway-api::tlsroutes
  deploy::gateway-api::udproutes
  deploy::gateway-api::backendtlspolicies
}

deploy::gateway-api::base-crds() {

        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_gatewayclasses.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_gateways.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_httproutes.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_referencegrants.yaml

        kubectl wait --for condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=${TIMEOUT}
        kubectl wait --for condition=Established crd/gateways.gateway.networking.k8s.io --timeout=${TIMEOUT}
        kubectl wait --for condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=${TIMEOUT}
        kubectl wait --for condition=Established crd/referencegrants.gateway.networking.k8s.io --timeout=${TIMEOUT}
}

deploy::gateway-api::grpcroutes() {
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_grpcroutes.yaml
        kubectl wait --for condition=Established crd/grpcroutes.gateway.networking.k8s.io --timeout=${TIMEOUT}
}

deploy::gateway-api::tlsroutes() {
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_tlsroutes.yaml
        kubectl wait --for condition=Established crd/tlsroutes.gateway.networking.k8s.io --timeout=${TIMEOUT}
}

deploy::gateway-api::udproutes() {
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_udproutes.yaml
        kubectl wait --for condition=Established crd/udproutes.gateway.networking.k8s.io --timeout=${TIMEOUT}
}

deploy::gateway-api::backendtlspolicies() {
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/${GATEWAY_API_CHANNEL}/gateway.networking.k8s.io_backendtlspolicies.yaml
        kubectl wait --for condition=Established crd/backendtlspolicies.gateway.networking.k8s.io --timeout=${TIMEOUT}
}
