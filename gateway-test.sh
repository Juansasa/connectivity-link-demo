#!/bin/bash

GATEWAY_NAME=${1:-toystore}
NAMESPACE=${2:-api-gateway}
SECRET_NAME=${3:-api-${GATEWAY_NAME}-tls}
HOSTNAME=${5:-toy-${NAMESPACE}.apps.r5ftk5n2q.stakater.cloud}

# Create a temporary directory for the certs
TMPDIR=$(mktemp -d)
CA_FILE="$TMPDIR/ca.crt"

# Always fetch the CA certificate from the root CA secret
oc get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}' | base64 -d > "$CA_FILE"

# Export the Gateway's external address as INGRESS_HOST (for OpenShift clusters)
export INGRESS_HOST=$(oc get gtw $GATEWAY_NAME -n $NAMESPACE -o jsonpath='{.status.addresses[0].value}')
echo "INGRESS_HOST: $INGRESS_HOST"

# Get the token from the keycloak
export JWT_TOKEN=$(curl -s -X POST 'https://keycloak-keycloak.apps.r5ftk5n2q.stakater.cloud/realms/kuadrant/protocol/openid-connect/token' -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=password' -d 'client_id=csn-api-test' -d 'username=jane' -d 'password=p' | jq -r .access_token)

# Test the /cars endpoint on the Gateway's external address using the fetched CA cert and correct Host header
curl -s -v --cacert "$CA_FILE" "https://$HOSTNAME/toy" -H "Authorization: Bearer $JWT_TOKEN"

# Clean up the temporary directory
rm -rf "$TMPDIR"
