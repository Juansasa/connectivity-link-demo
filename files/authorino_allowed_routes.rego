package authorino

import rego.v1

gateway := input.gateway_name
route := trim(input.context.request.http.path, "/")
allowed_routes := input.auth.identity.allowed_routes

allow if {
    gateway
    allowed_routes
    sprintf("%s:*", [gateway]) in allowed_routes
}

allow if {
    gateway
    route
    allowed_routes
    sprintf("%s:%s", [gateway, route]) in allowed_routes
} 