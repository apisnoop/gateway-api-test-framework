#!/usr/bin/env bash


deploy::metallb() {
  echo "deploy::metallb"

  KIND_NET_CIDR=$(docker network inspect ${KIND_NET} -f '{{json .IPAM.Config}}' | jq -r '.[]|select(.Subnet | contains("::") | not) | .Subnet')
  METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.200@")
  METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.250@")
  METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"

  cat << EOF > "${CONFIG_DIR}/metallb_crds.yaml"
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_IP_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF

  cat << EOF > "${CONFIG_DIR}/metallb_values.yaml"
configInline:
  address-pools:
  - name: default
    protocol: layer2
    addresses:
    - ${METALLB_IP_RANGE}
psp:
  create: false
EOF

  # install load-balancer (metal-lb)
  helm install --namespace metallb-system \
    --create-namespace \
    --repo https://metallb.github.io/metallb metallb metallb \
    --version ${METALLB_VERSION} \
    --values ${CONFIG_DIR}/metallb_values.yaml \
    --wait

  # wait until metalLB is running
  kubectl -n metallb-system wait --for=condition=Ready --selector="app.kubernetes.io/name=metallb" --timeout=600s pod
}
