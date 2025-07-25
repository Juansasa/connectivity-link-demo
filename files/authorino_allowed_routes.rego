# # Example Authorino input for OPA policy testing
# {
#   "context": {
#     "request": {
#       "http": {
#         "path": "/pets/123",  # The HTTP request path
#         "headers": {
#           "authorization": "Basic amFuZTpzZWNyZXQK",  # Basic Auth header (decoded: jane:secret)
#           "baggage": "eyJrZXkxIjoidmFsdWUxIn0="      # Custom metadata, base64-encoded JSON: {"key1":"value1"}
#         }
#       }
#     }
#   },
#   "auth": {
#     "identity": {
#       "username": "jane",           # Authenticated user's username
#       "fullname": "Jane Smith",     # Full name of the user
#       "email": "\u0006jane\u0012@petcorp.com\n"  # User's email (example with escaped chars)
#     }
#   }
# }

# *:*/*                                   Will allow everything
# GET:*/*                                 Will allow all GET
# *:test.com/admin/toy                    Will allow all method on host test.com and path /admin/toy
# *:*/admin/toy                           Will allow all method GET, POST etc on any host and path /admin/toy

import rego.v1

permission_pattern := `^([^:]+):([^/]*)(/.*)$`

method := input.context.request.http.method
host := input.context.request.http.host
path := input.context.request.http.path
permissions := input.auth.identity.allowed_routes

allow if {
    some permission in permissions
    matches := regex.find_all_string_submatch_n(permission_pattern, permission, -1)
    count(matches) > 0
    match := matches[0]
    count(match) > 3
    match[1] in ["*", method]
    match[2] in ["*", host]
    match[3] in ["/*", path]
}
