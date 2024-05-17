#!/usr/bin/env bash

source "./lib/k8s.sh"

deploy::kind() {
  echo "deploy::kind"
  config::kind::config

  # ERROR: failed to create cluster: node(s) already exist for a cluster with the name "kind"
  # ^^^ Check

  kind create cluster --config=${KIND_CONFIG} --image=${KIND_IMAGE}
}


config::kind::config() {

  echo "KIND_DISABLE_CNI: ${KIND_DISABLE_CNI}"
  case ${KIND_DISABLE_CNI} in

    "true")
      export KIND_CONFIG=${CONFIG_DIR}/kind-cni-disable.yaml
      ;;

    "false")
      export KIND_CONFIG=${CONFIG_DIR}/kind-cni-enable.yaml
      ;;

    *)
      echo "Error bad value for KIND_DISABLE_CNI"
      exit 1
      ;;
  esac

  echo "KIND_IMAGE: ${KIND_IMAGE}"
}

check::kind::cni() {
  echo "check::kind::cni"

  if [[ "${KIND_DISABLE_CNI}" == "true" ]] ; then
    deploy::k8s::cni
  fi

  # wait until coredns is running
  kubectl -n kube-system wait --for=condition=Ready --selector="k8s-app=kube-dns" --timeout=600s pod
}
