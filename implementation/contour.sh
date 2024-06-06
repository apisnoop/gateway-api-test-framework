#!/usr/bin/env bash


deploy::contour() {
  echo "deploy::contour"

  export CONTOUR_VERSION=${CONTOUR_VERSION:-v1.29.0}
  export CONTOUR_IMG=${CONTOUR_E2E_IMAGE:-ghcr.io/projectcontour/contour:${CONTOUR_VERSION}}
  echo "Using Contour image: ${CONTOUR_IMG}"
  echo "Using Contour version: ${CONTOUR_VERSION}"
  echo "Using Gateway API version: ${GATEWAY_API_VERSION}"

  kubectl apply -f https://raw.githubusercontent.com/projectcontour/contour/${CONTOUR_VERSION}/examples/gateway-provisioner/00-common.yaml
  kubectl apply -f https://raw.githubusercontent.com/projectcontour/contour/${CONTOUR_VERSION}/examples/gateway-provisioner/01-roles.yaml
  kubectl apply -f https://raw.githubusercontent.com/projectcontour/contour/${CONTOUR_VERSION}/examples/gateway-provisioner/02-rolebindings.yaml

  kubectl apply -f <(curl -s https://raw.githubusercontent.com/projectcontour/contour/${CONTOUR_VERSION}/examples/gateway-provisioner/03-gateway-provisioner.yaml | \
      yq eval '.spec.template.spec.containers[0].image = env(CONTOUR_IMG)' - | \
      yq eval '.spec.template.spec.containers[0].imagePullPolicy = "IfNotPresent"' - | \
      yq eval '.spec.template.spec.containers[0].args += "--contour-image="+env(CONTOUR_IMG)' -)

  kubectl apply -f https://raw.githubusercontent.com/projectcontour/contour/v1.29.0/examples/contour/01-crds.yaml
  kubectl -n projectcontour wait --for=condition=Ready --selector="control-plane=contour-gateway-provisioner" --timeout=180s pod

  cat << EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
EOF

}

run::contour::gateway-api-conformance() {
  echo "run::contour::gateway-api-conformance"

  export GATEWAY_API_REPO_PATH=${GATEWAY_API_REPO_PATH:-"${PWD}/repos/gateway-api}"}
  if [[ ! -d ${GATEWAY_API_REPO_PATH} ]]; then
    echo "GATEWAY_API_REPO_PATH: ${GATEWAY_API_REPO_PATH}"
    echo "Repo doesn't exists, cloning repo"

    mkdir -p repos
    cd $_ || exit
    git clone https://github.com/kubernetes-sigs/gateway-api.git
    cd - || exit
  fi
  pushd repos/gateway-api/conformance || exit 1

  git checkout ${GATEWAY_API_VERSION}

  SUPPORTED_FEATURES="Gateway,HTTPRoute"
  SKIP_TESTS="Mesh"
  CURRENT_DATE_TIME=$(date +"%Y%m%d-%H%M")
  REPORT="/tmp/conformance-suite-report-${CURRENT_DATE_TIME}-contour.yaml"

  GATEWAY_API_CONFORMANCE_TESTS=1 go test \
    -p 4 \
    --gateway-class contour \
    --supported-features "${SUPPORTED_FEATURES}" \
    --report-output=${REPORT} \
    --organization=projectcontour \
    --project=contour \
    --url=https://projectcontour.io/ \
    --version=v1.29.0 \
    --contact='@projectcontour/maintainers' \
    -test.run "TestConformance" \
    -test.skip "${SKIP_TESTS}" \
    -test.v 10

  popd || exit

  echo -e "\n\nConformance Suite completed.\n${IMPLEMENTATION} report saved: ${REPORT}.\n\n"
  cat "${REPORT}"
}
