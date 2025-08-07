# CSN Gateway API

A Helm chart for deploying a single API gateway with JWT authentication, rate limiting, and TLS termination using Istio and Kuadrant.

## Requirements

- Istio operator installed
- Default mesh configured
- Gateway API support enabled
- Docker pull secret in `files/.dockerconfigjson`

## Quick Start

1. **Configure your gateway** in `values.yaml`:
```yaml
gateway:
  name: my-gateway
  namespace: api-gateway
  rootDomain: apps.example.com
  jwt:
    issuerUrl: https://keycloak.example.com/realms/my-realm
  routes:
    - name: api
      namespace: my-service
      rules:
        - matches:
          - path:
              type: PathPrefix
              value: "/api"
            method: GET
          backendRefs:
            - name: my-service
              port: 80
```

2. **Deploy the chart**:
```bash
helm install my-gateway . -n api-gateway
```

## JWT Authentication

The gateway supports fine-grained access control using JWT claims with the `allowed_routes` format:

```
{method}:{host}{path}
```

### Examples
- `GET:*/*` - Allow all GET requests
- `POST:api.example.com/admin` - Allow POST to specific host/path
- `*:*/admin/*` - Allow all methods to admin paths

### Keycloak Setup

1. Create a client mapper for `allowed_routes`:
   - **Mapper Type:** `User Attribute`
   - **User Attribute:** `allowed_routes`
   - **Token Claim Name:** `allowed_routes`
   - **Claim JSON Type:** `JSON`
   - **Multivalued:** ON

2. Assign routes to users via user attributes:
```json
[
  "GET:*/*",
  "POST:api.example.com/admin"
]
```

## Rate Limiting

Configure rate limits per route in `values.yaml`:

```yaml
routes:
  - name: api
    rateLimit:
      "global":
        rates:
        - limit: 100
          window: 1m
      "per-user":
        rates:
        - limit: 10
          window: 1m
        counters:
        - expression: "auth.identity.username"
```

## Usage

1. **Get a JWT token**:
```bash
curl -X POST 'https://keycloak.example.com/realms/my-realm/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=my-client' \
  -d 'username=user' \
  -d 'password=pass'
```

2. **Access your API**:
```bash
curl -H "Authorization: Bearer <token>" https://api-apps.example.com/api/resource
```

## Configuration

See `values.yaml` for all available configuration options including:
- Gateway settings (name, namespace, domain)
- JWT authentication (issuer URL)
- Routes with rate limiting and backend services
- TLS policies
