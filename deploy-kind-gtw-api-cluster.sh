#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Set or override vars as required
echo "IMPLEMENTATION: ${IMPLEMENTATION}"
export IMPLEMENTATION=${IMPLEMENTATION,,}

export TIMEOUT=${TIMEOUT:-"5m"}
export CLEAN_UP=${CLEAN_UP:-"true"}
export METALLB_VERSION=${METALLB_VERSION:-"0.12.1"}
export GATEWAY_API_VERSION=${GATEWAY_API_VERSION:-"v1.1.0"}
export GATEWAY_API_CHANNEL=${GATEWAY_API_CHANNEL:-"standard"}
export GATEWAY_API_CHANNEL=${GATEWAY_API_CHANNEL,,}

export KIND_IMAGE=${KIND_IMAGE:-"kindest/node:v1.30.0@sha256:047357ac0cfea04663786a612ba1eaba9702bef25227a794b52890dd8bcd692e"}
export KIND_NET=${KIND_NET:-"kind"}
export KIND_DISABLE_CNI=${KIND_DISABLE_CNI:-"false"}
export KIND_DISABLE_CNI=${KIND_DISABLE_CNI,,}

echo "CONFIG_DIR: ${CONFIG_DIR}"

source "./lib/init.sh"

deploy::kind
deploy::gateway-api
check::kind::cni
deploy::metallb
config::implementation
