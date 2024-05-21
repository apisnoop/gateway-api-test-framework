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

  SUPPORTED_FEATURES="Gateway,HTTPRoute,HTTPRouteDestinationPortMatching,HTTPRouteHostRewrite,HTTPRouteMethodMatching,HTTPRoutePathRedirect,HTTPRoutePathRewrite,HTTPRoutePortRedirect,HTTPRouteQueryParamMatching,HTTPRouteRequestMirror,HTTPRouteRequestMultipleMirrors,HTTPRouteResponseHeaderModification,HTTPRouteSchemeRedirect,ReferenceGrant,TLSRoute"
  SKIP_TESTS=""
  CURRENT_DATE_TIME=$(date +"%Y%m%d-%H%M")
  REPORT="/tmp/conformance-suite-report-${CURRENT_DATE_TIME}-cilium.log"

  GATEWAY_API_CONFORMANCE_TESTS=1 go test \
    -p 4 \
    -v ./operator/pkg/gateway-api \
    --gateway-class cilium \
    --supported-features "${SUPPORTED_FEATURES}" \
    --report-output=${REPORT} \
    --organization=cilium \
    --project=cilium \
    --url=https://github.com/cilium/cilium \
    --version=0.15.4 \
    --contact='https://github.com/cilium/community/blob/main/roles/Maintainers.md' \
    -test.run "TestConformance" \
    -test.skip "${SKIP_TESTS}"

  popd || exit

  echo -e "\n\nConformance Suite completed.\n${IMPLEMENTATION} report saved: ${REPORT}.\n\n"
  cat "${REPORT}"
}
