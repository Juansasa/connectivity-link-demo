#### Requireements
* Install Istio operator
* Setup default mesh
* Enable Gateway API support
* Add docker pullsecret in files/.dockerconfigjson

## JWT Claims for Gateway and Route Authorization

This chart supports fine-grained access control using JWT claims. You can control which gateways and routes a user can access by including an `allowed_routes` claim in their JWT. The policy logic supports both wildcard and comma-separated route lists for maximum flexibility.

### Claim Structure

- **Wildcard access:**
  - `toystore:*` grants access to all routes in the `toystore` gateway.
- **Comma-separated list:**
  - `toystore:admin,toy,cashout` grants access only to the `admin`, `toy`, and `cashout` routes in the `toystore` gateway.
- **Multiple gateways:**
  - You can include multiple entries for different gateways.

#### Example JWT Payload
```json
{
  "allowed_routes": [
    "toystore:*",
    "payments:checkout,refund"
  ]
}
```

#### Example: Limited Access
```json
{
  "allowed_routes": [
    "toystore:admin,toy",
    "payments:checkout"
  ]
}
```

### How the Policy Works

The policy template checks the `allowed_routes` claim for an entry matching the current gateway. It allows access if:
- The entry is a wildcard (e.g., `toystore:*`), or
- The current route is listed in the comma-separated list (e.g., `toystore:admin,toy` and the route is `admin` or `toy`).

### Best Practices
- Use `gateway:*` for admin or power users.
- Use `gateway:route1,route2` for users with limited access.
- Issue JWTs with the appropriate `allowed_routes` claim for each user or client.

## Setting Up Keycloak for JWT-based Gateway and Route Authorization

### 1. Create a Realm and Client
- Log in to the Keycloak admin console.
- Create a new **Realm** (or use an existing one).
- Under the realm, create a new **Client** (e.g., `api-gateway`).
  - Set **Access Type** to `confidential` or `public` as needed.
  - Set **Valid Redirect URIs** and **Web Origins** as appropriate for your app.

### 2. Configure Client to Issue JWTs
- In the client settings, ensure **Standard Flow Enabled** is ON.
- Set **ID Token Signature Algorithm** to `RS256` (recommended).
- Under **Client Scopes**, add or create a scope for custom claims if needed.

### 3. Set a Custom Audience (aud) Claim
- By default, Keycloak sets the `aud` claim to the client ID.
- You can choose your own value for the audience (`aud`) claim. The root domain of your API gateway (e.g., `https://api.apps.r5ftk5n2q.stakater.cloud`) is a recommended example, but not a strict requirement. The important thing is that the value you configure in Keycloak matches the value you set in your chart's `audiences` configuration.
- **Best practices when choosing an audience value:**
  - Use a value that uniquely identifies your API or gateway (such as a domain, URL, or a descriptive string).
  - Avoid using generic values that could overlap with other services.
  - Ensure consistency: the value in the JWT's `aud` claim must exactly match what your gateway expects.
  - For multi-tenant or multi-environment setups, consider including environment or tenant info in the audience value.
- To set a custom audience (such as your API gateway's root domain), add a protocol mapper:
  - Go to your client in Keycloak.
  - Click the **Mappers** tab.
  - Click **Create**.
  - Set:
    - **Name:** `audience`
    - **Mapper Type:** `Audience`
    - **Included Client Audience:** your chosen audience value (e.g., `https://apps.r5ftk5n2q.stakater.cloud`)
    - **Add to ID token:** ON (if you use ID tokens)
    - **Add to access token:** ON (for API access)
    - **Add to userinfo:** (optional)
  - Save the mapper.
- Now, tokens will include your chosen value as an audience in the `aud` claim.

### 4. Add Custom Claims for Gateway/Route Access
- Go to **Client Scopes** > (your scope) > **Mappers**.
- Click **Create** to add a new mapper:
  - **Name:** `allowed_routes`
  - **Mapper Type:** `User Attribute`
  - **User Attribute:** `allowed_routes`
  - **Token Claim Name:** `allowed_routes`
  - **Claim JSON Type:** `String` or `JSON`
  - **Add to ID token** and **Add to access token:** ON

### 5. Assign Claims to Users
- Go to **Users** > (select a user) > **Attributes**.
- Add an attribute:
  - **Key:** `allowed_routes`
  - **Value:**
    ```
    [
      "toystore:*",
      "payments:checkout,refund"
    ]
    ```
  - (Or use the structure you want for your access control.)

### 6. Obtain a Token
- Use the Keycloak login flow (OIDC) to obtain an access token for your user.
- Decode the token (e.g., at [jwt.io](https://jwt.io/)) and verify the `allowed_routes` and `aud` claims are present and correct.

### 7. Configure Your Gateway/Chart
- Set the `issuerUrl` in your Helm values to your Keycloak realm’s OIDC endpoint, e.g.:
  ```
  https://<keycloak-host>/realms/<realm-name>
  ```
- Set the `audiences` in your Helm values to your root domain, e.g.:
  ```
  audiences:
    - https://apps.r5ftk5n2q.stakater.cloud
  ```
- Deploy your chart as usual.

### Best Practices
- Use Keycloak groups or roles to automate claim assignment for many users.
- Use Keycloak’s built-in mappers to transform group/role membership into claims.
- Regularly review and audit user claims for security.
