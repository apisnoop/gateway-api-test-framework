#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo "CONFIG_DIR: ${CONFIG_DIR}"
export IMPLEMENTATION=${IMPLEMENTATION,,}
echo "IMPLEMENTATION: ${IMPLEMENTATION}"

if [[ "${IMPLEMENTATION}" == "none" ]] ; then
  echo "Error: Deploy an implementation first."
  exit 1
fi

export IMPLEMENTATION_REPO_PATH=${IMPLEMENTATION_REPO_PATH:-"${PWD}/repos/${IMPLEMENTATION}"}
source "./lib/init.sh"

export GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.1.0}"

run::${IMPLEMENTATION}::conformance
