#!/bin/bash

GATEWAY_NAME=${1:-gateway}
NAMESPACE=${2:-kuadrant-system}
SECRET_NAME=${3:-api-gateway-tls}
HOSTNAME=${5:-api.test.csn.se}

# Create a temporary directory for the certs
TMPDIR=$(mktemp -d)
CA_FILE="$TMPDIR/ca.crt"

# Always fetch the CA certificate from the root CA secret
oc get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}' | base64 -d > "$CA_FILE"

# Export the Gateway's external address as INGRESS_HOST (for OpenShift clusters)
export INGRESS_HOST=$(oc get gtw $GATEWAY_NAME -n $NAMESPACE -o jsonpath='{.status.addresses[0].value}')
echo "INGRESS_HOST: $INGRESS_HOST"

# Test the /cars endpoint on the Gateway's external address using the fetched CA cert and correct Host header
curl -vs --cacert "$CA_FILE" --resolve $HOSTNAME:443:$INGRESS_HOST "https://$HOSTNAME/cars"

# Clean up the temporary directory
rm -rf "$TMPDIR"
