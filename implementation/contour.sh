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

  kubectl apply -f <(curl -s https://raw.githubusercontent.com/projectcontour/contour/main/examples/gateway-provisioner/03-gateway-provisioner.yaml | \
      yq eval '.spec.template.spec.containers[0].image = env(CONTOUR_IMG)' - | \
      yq eval '.spec.template.spec.containers[0].imagePullPolicy = "IfNotPresent"' - | \
      yq eval '.spec.template.spec.containers[0].args += "--contour-image="+env(CONTOUR_IMG)' -)

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
