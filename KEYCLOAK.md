## Install Keycloak

oc create namespace keycloak
oc -n keycloak apply -f https://raw.githubusercontent.com/kuadrant/authorino-examples/main/keycloak/keycloak-deploy.yaml

## Import realm from ./files/realm.json