#!/usr/bin/env bash


deploy::istio() {
  echo "deploy::istio"

  istioctl install --set profile=minimal --skip-confirmation

  cat << EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller
EOF

}
