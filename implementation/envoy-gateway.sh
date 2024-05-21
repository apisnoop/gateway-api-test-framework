#!/usr/bin/env bash


deploy::envoy-gateway() {
  echo "deploy::envoy-gateway"

  helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.0.1 -n envoy-gateway-system --create-namespace
  kubectl -n envoy-gateway-system wait --for=condition=Ready --selector="control-plane=envoy-gateway" --timeout=120s pod

  kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/main/examples/kubernetes/quickstart.yaml
  sleep 20
  kubectl -n envoy-gateway-system wait --for=condition=Ready --selector="app.kubernetes.io/name=envoy" --timeout=120s pod
}

run::envoy-gateway::conformance() {
  echo "run::envoy-gateway::conformance"

  if [[ ! -d ${IMPLEMENTATION_REPO_PATH} ]]; then
    echo "IMPLEMENTATION_REPO_PATH: ${IMPLEMENTATION_REPO_PATH}"
    echo "Repo for \"${IMPLEMENTATION}\" doesn't exists, cloning repo"

    mkdir -p repos
    cd $_ || exit
    # git clone --depth 1 --branch ${GATEWAY_API_VERSION} https://github.com/kubernetes-sigs/gateway-api envoy-gateway
    git clone --branch ${GATEWAY_API_VERSION} https://github.com/kubernetes-sigs/gateway-api envoy-gateway
    cd - || exit
  fi
  pushd repos/envoy-gateway || exit 1

  SUPPORTED_FEATURES="Gateway,HTTPRoute"
  SKIP_TESTS=""
  CURRENT_DATE_TIME=$(date +"%Y%m%d-%H%M")
  REPORT="/tmp/conformance-suite-report-${CURRENT_DATE_TIME}-envoy-gateway.log"

  GATEWAY_API_CONFORMANCE_TESTS=1 go test ./conformance \
    -debug \
    --gateway-class eg \
    --supported-features "${SUPPORTED_FEATURES}" \
    --report-output=${REPORT} \
    --organization=envoyproxy \
    --project=envoy-gateway \
    --url=https://github.com/envoyproxy/gateway \
    --version=v1.0.1 \
    --contact='https://github.com/envoyproxy/gateway/blob/main/GOVERNANCE.md' \
    -test.run "TestConformance" \
    -test.skip "${SKIP_TESTS}"

  popd || exit

  echo -e "\n\nConformance Suite completed.\n${IMPLEMENTATION} report saved: ${REPORT}.\n\n"
  cat "${REPORT}"
}
