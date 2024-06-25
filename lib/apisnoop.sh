#!/usr/bin/env bash

deploy::apisnoop() {
    echo "deploy::apisnoop"

    APISNOOP_IMAGE_TAG="${APISNOOP_VERSION:-v20240623-auditlogger-1.2.11-68-g854618f}"

    helm repo add --force-update apisnoop https://kubernetes-sigs.github.io/apisnoop

    helm upgrade \
        -i --create-namespace \
        --namespace apisnoop \
        --reuse-values \
        --set image.tag="$APISNOOP_IMAGE_TAG" \
        --set service.type="NodePort" \
        --set service.nodePort="30432" \
        snoopdb \
        apisnoop/snoopdb

    helm upgrade \
        -i --create-namespace \
        --namespace apisnoop \
        --reuse-values \
        --set image.tag="$APISNOOP_IMAGE_TAG" \
        auditlogger \
        apisnoop/auditlogger
}
