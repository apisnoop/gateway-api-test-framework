#!/usr/bin/env bash


deploy::envoy-gateway() {
  echo "deploy::envoy-gateway"

  export IMPLEMENTATION_VERSION=${IMPLEMENTATION_VERSION:-"v1.0.1"}
  helm install eg oci://docker.io/envoyproxy/gateway-helm --version ${IMPLEMENTATION_VERSION} -n envoy-gateway-system --create-namespace
  kubectl -n envoy-gateway-system wait --for=condition=Ready --selector="control-plane=envoy-gateway" --timeout=120s pod

  kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/main/examples/kubernetes/quickstart.yaml
  sleep 20
  kubectl -n envoy-gateway-system wait --for=condition=Ready --selector="app.kubernetes.io/name=envoy" --timeout=120s pod
}

run::envoy-gateway::conformance() {
  echo "run::envoy-gateway::conformance"
  run::envoy-gateway::gateway-api-conformance
}

run::envoy-gateway::gateway-api-conformance() {
  echo "run::envoy-gateway::gateway-api-conformance"

  mkdir -p repos
  cd $_ || exit
  [ -d "gateway-api-${GATEWAY_API_VERSION}" ] || git clone https://github.com/kubernetes-sigs/gateway-api.git gateway-api-"${GATEWAY_API_VERSION}"
  cd - || exit
  pushd repos/gateway-api-"${GATEWAY_API_VERSION}" || exit 1
  git reset --hard HEAD
  git checkout "${GATEWAY_API_VERSION}"
  git apply ../../lib/gateway-api-"${GATEWAY_API_VERSION}"-useragent.patch

  SUPPORTED_FEATURES="Gateway,HTTPRoute"
  SKIP_TESTS="Mesh"
  CURRENT_DATE_TIME=$(date +"%Y%m%d-%H%M")
  REPORT="/tmp/conformance-suite-report-${CURRENT_DATE_TIME}-${IMPLEMENTATION}.yaml"

  GATEWAY_API_CONFORMANCE_TESTS=1 go test \
    -p 4 \
    ./conformance \
    --gateway-class eg \
    --supported-features "${SUPPORTED_FEATURES}" \
    --report-output=${REPORT} \
    --organization=envoyproxy \
    --project=envoy-gateway \
    --url=https://github.com/envoyproxy/gateway \
    --version=v1.0.1 \
    --contact=https://github.com/envoyproxy/gateway/blob/main/GOVERNANCE.md \
    -test.run "TestConformance" \
    -test.skip "${SKIP_TESTS:-}" \
    -test.v 10

  popd || exit

  print::report
}
