#!/usr/bin/env bash
# Installs Envoy Gateway on the CCE cluster and applies the routing manifests.
# Upload this file into CloudShell (toolbar → Upload), then: bash install-envoy-gateway.sh
#
# Assumes you've also uploaded the k8s/ manifests, OR run this from a checkout of the repo
# (git clone <your repo>, cd into it, then run this). Adjust K8S_DIR if needed.
set -euo pipefail

ENVOY_GATEWAY_VERSION="v1.9.1" # pin explicitly; bump deliberately
NAMESPACE="envoy-gateway-system"
K8S_DIR="${K8S_DIR:-k8s}" # override with: K8S_DIR=/path/to/k8s bash install-envoy-gateway.sh

echo ">> Installing Envoy Gateway ${ENVOY_GATEWAY_VERSION}..."
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version "${ENVOY_GATEWAY_VERSION}" \
  -n "${NAMESPACE}" --create-namespace

echo ">> Waiting for the controller to become Available (up to 5m)..."
kubectl wait --timeout=5m -n "${NAMESPACE}" \
  deployment/envoy-gateway --for=condition=Available

echo ">> Applying routing manifests..."
kubectl apply -f "${K8S_DIR}/envoy-gatewayclass.yaml" # GatewayClass + EnvoyProxy (carries elb.id)
kubectl apply -f "${K8S_DIR}/envoy-gateway.yaml"      # Gateway (HTTP :80 listener)
kubectl apply -f "${K8S_DIR}/frontend-httproute.yaml" # / -> imto-test-frontend-svc:3000

echo ">> Done. Check the Gateway got an address:"
kubectl get gateway -n "${NAMESPACE}" imto-gateway -o wide
