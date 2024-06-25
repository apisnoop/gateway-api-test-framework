#!/usr/bin/env bash

echo "PWD: ${PWD}"
# she llcheck source=common/scripts/kind_provisioner.sh
#

ROOT=${PWD}


# shellcheck source=lib/kind.sh
source "${ROOT}/lib/kind.sh"
source "${PWD}/lib/apisnoop.sh"
source "${PWD}/lib/implementation.sh"
source "${PWD}/lib/gateway-api.sh"
source "${PWD}/lib/k8s.sh"
source "${PWD}/lib/metallb.sh"
source "${PWD}/implementation/${IMPLEMENTATION}.sh"
