#!/usr/bin/env bash


config::implementation() {
  echo "config::implementation"

  case ${IMPLEMENTATION} in

    "cilium")
      deploy::cilium::gatewayclass
      ;;

    "contour")
      deploy::contour
      ;;

    "envoy-gateway")
      deploy::envoy-gateway
      ;;

    "istio")
      deploy::istio
      ;;

    "none")
      echo "No gateway-api implementation requested."
      ;;

    *)
      echo "Error: Implementation unknown, exiting"
      exit 1
      ;;
  esac

  if [[ ${IMPLEMENTATION} != "none" ]] ; then
    kubectl get gc
    GTWCLASS_NAME=$(kubectl get gc -ojsonpath='{.items[0].metadata.name}')
    kubectl get gc $GTWCLASS_NAME -ojsonpath='{.status}' | jq
  fi
}
