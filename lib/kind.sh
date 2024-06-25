#!/usr/bin/env bash

source "./lib/k8s.sh"

deploy::kind() {
  echo "deploy::kind"
  config::kind::config

  if kind::cluster::exists "${KIND_NET}" ; then
      echo "cluster \"${KIND_NET}\" already exists"
      exit 2
  fi

  cd $(dirname ${KIND_CONFIG}) || exit
  kind create cluster --config=${KIND_CONFIG} --image=${KIND_IMAGE}
  cd - || exit

  # Print the k8s version for verification
  kubectl version
}

config::kind::config() {

  echo "KIND_DISABLE_CNI: ${KIND_DISABLE_CNI}"
  case ${KIND_DISABLE_CNI} in

    "true" | "false")
      config::kind::${ENABLE_APISNOOP}::${KIND_DISABLE_CNI}
      ;;

    *)
      echo "Error bad value for KIND_DISABLE_CNI"
      exit 1
      ;;
  esac

  echo "KIND_CONFIG: ${KIND_CONFIG}"
  echo "KIND_IMAGE: ${KIND_IMAGE}"
}

# config::kind::ENABLE_APISNOOP::KIND_DISABLE_CNI
config::kind::false::false() {
      export KIND_CONFIG=${CONFIG_DIR}/kind-cni-enable.yaml
}

config::kind::false::true() {
      export KIND_CONFIG=${CONFIG_DIR}/kind-cni-disable.yaml
}

config::kind::true::false() {
      export KIND_CONFIG=${CONFIG_DIR}/kind-apisnoop-cni-enable.yaml
}

config::kind::true::true() {
      export KIND_CONFIG=${CONFIG_DIR}/kind-apisnoop-cni-disable.yaml
}

check::kind::cni() {
  echo "check::kind::cni"

  if [[ "${KIND_DISABLE_CNI}" == "true" ]] ; then
    deploy::k8s::cni
  fi

  # wait until coredns is running
  kubectl -n kube-system wait --for=condition=Ready --selector="k8s-app=kube-dns" --timeout=600s pod
}

kind::cluster::exists() {
  kind get clusters | grep -q "$1"
}
