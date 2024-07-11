#!/usr/bin/env bash

export IMPLEMENTATION_VERSION=${IMPLEMENTATION_VERSION:-"1.22.1"}

deploy::istio() {
  echo "deploy::istio"

  check_helm_repo_list=$(helm repo list -ojson | jq -c '.[] | select( .name | contains("istio"))' | jq -c 'select( .url | contains("https://istio-release.storage.googleapis.com/charts"))')
  if [[ "${#check_helm_repo_list}" -eq 0 ]] ; then
    helm repo add istio https://istio-release.storage.googleapis.com/charts
  fi

  kubectl create ns istio-system
  helm install istio-base istio/base -n istio-system --set defaultRevision=default --version "${IMPLEMENTATION_VERSION}"
  helm install istiod istio/istiod -n istio-system --version "${IMPLEMENTATION_VERSION}" --wait

  cat << EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller
EOF

}

run::istio::conformance() {
  echo "run::istio::conformance"

  mkdir -p repos
  cd $_ || exit
  [ -d "gateway-api-${GATEWAY_API_VERSION}" ] || git clone https://github.com/kubernetes-sigs/gateway-api.git gateway-api-"${GATEWAY_API_VERSION}"
  cd - || exit
  pushd repos/gateway-api-"${GATEWAY_API_VERSION}" || exit 1
  git reset --hard HEAD
  git checkout "${GATEWAY_API_VERSION}"
  git apply ../../lib/gateway-api-"${GATEWAY_API_VERSION}"-useragent.patch

  SUPPORTED_FEATURES="Gateway,HTTPRoute,HTTPRouteDestinationPortMatching,HTTPRouteHostRewrite,HTTPRouteMethodMatching,HTTPRoutePathRedirect,HTTPRoutePathRewrite,HTTPRoutePortRedirect,HTTPRouteQueryParamMatching,HTTPRouteRequestMirror,HTTPRouteRequestMultipleMirrors,HTTPRouteResponseHeaderModification,HTTPRouteSchemeRedirect,ReferenceGrant,TLSRoute"
  SKIP_TESTS=""
  CURRENT_DATE_TIME=$(date +"%Y%m%d-%H%M")
  REPORT="/tmp/conformance-suite-report-${CURRENT_DATE_TIME}-istio.yaml"

  GATEWAY_API_CONFORMANCE_TESTS=1 go test \
    -p 4 \
    ./conformance/ \
    --gateway-class istio \
    --supported-features "${SUPPORTED_FEATURES:-}" \
    --report-output=${REPORT} \
    --organization=istio \
    --project=istio \
    --url=https://istio.io/ \
    --version="$IMPLEMENTATION_VERSION" \
    --contact='@istio/maintainers' \
    -test.run "TestConformance" \
    -test.skip "${SKIP_TESTS:-}" \
    -test.v 10

  popd || exit

  print::report
}
