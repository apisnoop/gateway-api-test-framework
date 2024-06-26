#!/usr/bin/env bash

export IMPLEMENTATION_VERSION=${IMPLEMENTATION_VERSION:-"1.22.1"}

deploy::istio() {
  echo "deploy::istio"

  istioctl install --set profile=minimal --set tag="${IMPLEMENTATION_VERSION}" --skip-confirmation

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

  if [[ ! -d ${IMPLEMENTATION_REPO_PATH} ]]; then
    echo "IMPLEMENTATION_REPO_PATH: ${IMPLEMENTATION_REPO_PATH}"
    echo "Repo for \"${IMPLEMENTATION}\" doesn't exists, cloning repo"

    mkdir -p repos
    cd $_ || exit
    git clone https://github.com/istio/istio.git
    cd - || exit
  fi
  pushd repos/istio || exit 1
  git fetch --tags -a
  git checkout "$IMPLEMENTATION_VERSION"

  SUPPORTED_FEATURES="Gateway,HTTPRoute,HTTPRouteDestinationPortMatching,HTTPRouteHostRewrite,HTTPRouteMethodMatching,HTTPRoutePathRedirect,HTTPRoutePathRewrite,HTTPRoutePortRedirect,HTTPRouteQueryParamMatching,HTTPRouteRequestMirror,HTTPRouteRequestMultipleMirrors,HTTPRouteResponseHeaderModification,HTTPRouteSchemeRedirect,ReferenceGrant,TLSRoute"
  SKIP_TESTS=""
  CURRENT_DATE_TIME=$(date +"%Y%m%d-%H%M")
  REPORT="/tmp/conformance-suite-report-${CURRENT_DATE_TIME}-istio.yaml"

  go test \
    -v -timeout 60m \
    -run TestGatewayConformance \
    -skip "$SKIP_TESTS" \
    ./tests/integration/pilot \
    -tags=integ \
    --gateway-class=istio \
    --all-features \
    --contact='@istio/maintainers' \
    --version="$IMPLEMENTATION_VERSION" \
    --report-output="$REPORT" \
    --url="https://istio.io" \
    --project=istio \
    --organization=istio \
    --supported-features="$SUPPORTED_FEATURES"

  popd || exit

  echo -e "\n\nConformance Suite completed.\n${IMPLEMENTATION} report saved: ${REPORT}.\n\n"
  cat "${REPORT}"
}
