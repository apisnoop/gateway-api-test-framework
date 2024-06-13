#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# NOTE
#   - have kind with gateway-api and an implementation installed
#   - have snoopdb running by setting ENABLE_SNOOP to true
#     or docker run --name snoopdb -it --rm -p 5432:5432 gcr.io/k8s-staging-apisnoop/snoopdb:v20240310-auditlogger-1.2.11-30-g3c40359

cd "$(git rev-parse --show-toplevel)"

kubectl get --raw /openapi/v2 > /tmp/openapi.json
# kubectl -n apisnoop port-forward snoopdb-0 5432:5432&
kubectl -n default cp /tmp/openapi.json apisnoop-kind-control-plane:/openapi.json
# or
#   docker cp /tmp/openapi.json snoopdb:/openapi.json

mkdir -p ./resources/coverage/
psql postgresql://postgres@localhost -f ./lib/load_live_open_api.sql
psql postgresql://postgres@localhost -f ./lib/generate_latest_gateway_api_coverage_json.sql
