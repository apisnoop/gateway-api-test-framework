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
        echo "No gateway-api channel requested."
        ;;

      *)
        echo "Error: GATEWAY_API_CHANNEL unknown, exiting"
        exit 1
        ;;
    esac
  fi
}

deploy::gateway-api::standard::v1.1.0(){
  kustomize build github.com/kubernetes-sigs/gateway-api//config/crd?ref=v1.1.0 | kubectl apply -f -
  kubectl wait --for condition=Established crd --all
}

deploy::gateway-api::standard::v1.0.0(){
  kustomize build github.com/kubernetes-sigs/gateway-api//config/crd?ref=v1.0.0 | kubectl apply -f -
  kubectl wait --for condition=Established crd --all
}

deploy::gateway-api::experimental::v1.1.0(){
  kustomize build github.com/kubernetes-sigs/gateway-api//config/crd?ref=v1.1.0 | kubectl apply -f -
  kustomize build github.com/kubernetes-sigs/gateway-api//config/crd/experimental?ref=v1.1.0 | kubectl apply -f -
  kubectl wait --for condition=Established crd --all
}

deploy::gateway-api::experimental::v1.0.0(){
  kustomize build github.com/kubernetes-sigs/gateway-api//config/crd?ref=v1.0.0 | kubectl apply -f -
  kustomize build github.com/kubernetes-sigs/gateway-api//config/crd/experimental?ref=v1.0.0 | kubectl apply -f -
  kubectl wait --for condition=Established crd --all
}
