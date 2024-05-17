#!/usr/bin/env bash


deploy::contour() {
  echo "deploy::contour"

  # TODO: install resources

  cat << EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
EOF

}
