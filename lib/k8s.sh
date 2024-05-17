#!/usr/bin/env bash


deploy::k8s::cni() {
  echo "deploy::k8s:cni"

  case ${IMPLEMENTATION} in

    "cilium")
      deploy::cilium
      ;;

    *)
      echo "Error: CNI unknown, exiting"
      exit 1
      ;;
  esac
}
