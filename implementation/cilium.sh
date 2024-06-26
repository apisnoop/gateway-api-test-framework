#!/usr/bin/env bash

export KIND_DISABLE_CNI="true"
export GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.1.0}"

export IMPLEMENTATION_VERSION=${IMPLEMENTATION_VERSION:-"v1.15.4"}
deploy::cilium() {
  echo "deploy::cilium"

  export API_SERVER_IP=$(kubectl get nodes  -owide | grep control-plane | awk '{print $6}')
  check_helm_repo_list=$(helm repo list -ojson | jq -c '.[] | select( .name | contains("cilium"))' | jq -c 'select( .url | contains("https://helm.cilium.io/"))')
  if [[ "${#check_helm_repo_list}" -eq 0 ]] ; then
    helm repo add cilium https://helm.cilium.io
  fi
  echo "Checking helm repo list.... ${check_helm_repo_list}"

  helm upgrade --install cilium cilium/cilium \
	       --version ${IMPLEMENTATION_VERSION} \
	       --namespace kube-system \
	       --set kubeProxyReplacement=strict \
	       --set k8sServiceHost=${API_SERVER_IP} \
	       --set k8sServicePort=6443 \
	       --set gatewayAPI.enabled=true
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

run::cilium::conformance() {
  echo "run::cilium::conformance"

  if [[ ! -d ${IMPLEMENTATION_REPO_PATH} ]]; then
    echo "IMPLEMENTATION_REPO_PATH: ${IMPLEMENTATION_REPO_PATH}"
    echo "Repo for \"${IMPLEMENTATION}\" doesn't exists, cloning repo"

    mkdir -p repos
    cd $_ || exit
    git clone https://github.com/cilium/cilium.git
    cd - || exit
  fi
  pushd repos/cilium || exit 1
  git fetch --tags -a
  git checkout "$IMPLEMENTATION_VERSION"

  git checkout ${IMPLEMENTATION_VERSION}

  case ${GATEWAY_API_VERSION} in

    "v1.0.0")
      SUPPORTED_FEATURES="Gateway,HTTPRoute,HTTPRouteDestinationPortMatching,HTTPRouteHostRewrite,HTTPRouteMethodMatching,HTTPRoutePathRedirect,HTTPRoutePathRewrite,HTTPRoutePortRedirect,HTTPRouteQueryParamMatching,HTTPRouteRequestMirror,HTTPRouteRequestMultipleMirrors,HTTPRouteResponseHeaderModification,HTTPRouteSchemeRedirect,ReferenceGrant,TLSRoute"
      EXEMPT_FEATURES="GRPCRoute,GatewayPort8080,GatewayStaticAddresses,HTTPRouteParentRefPort,GRPCExactMethodMatching,HTTPRouteBackendProtocolH2C,HTTPRouteBackendProtocolWebSocket"
      ;;

    "v1.1.0")
      CONFORMANCE_PROFILES="HTTP,TLS"
      SUPPORTED_FEATURES="ReferenceGrant,HTTPRoute,TLSRoute,HTTPRouteQueryParamMatching,HTTPRouteMethodMatching,GatewayClassObservedGenerationBump,HTTPRouteHostRewrite,HTTPRoutePathRewrite,HTTPRouteSchemeRedirect,HTTPRoutePathRedirect,HTTPRoutePortRedirect,HTTPRouteRequestMirror,HTTPRouteRequestMultipleMirrors"
      ;;

    *)
      echo "Error: GATEWAY_API_VERSION: ${GATEWAY_API_VERSION} unknown, exiting"
      exit 1
      ;;
  esac

  CURRENT_DATE_TIME=$(date +"%Y%m%d-%H%M")
  REPORT="/tmp/conformance-suite-report-${CURRENT_DATE_TIME}-cilium.yaml"

  GATEWAY_API_CONFORMANCE_TESTS=1 go test \
    -p 4 \
    -v ./operator/pkg/gateway-api \
    --gateway-class cilium \
    --report-output=${REPORT} \
    --organization=cilium \
    --project=cilium \
    --url=https://github.com/cilium/cilium \
    --version="$IMPLEMENTATION_VERSION" \
    --contact='https://github.com/cilium/community/blob/main/roles/Maintainers.md' \
    --supported-features="${SUPPORTED_FEATURES:-""}" \
    --exempt-features="${EXEMPT_FEATURES:-""}" \
    --conformance-profiles="${CONFORMANCE_PROFILES:-""}" \
    -test.run "TestConformance" \
    -test.skip "${SKIP_TESTS:-""}" \
    ${ALL_FEATURES:-""}

  popd || exit

  echo -e "\n\nConformance Suite completed.\n${IMPLEMENTATION} report saved: ${REPORT}.\n\n"
  cat "${REPORT}"
}
