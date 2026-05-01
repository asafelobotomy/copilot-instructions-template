---
name: api-design
description: Design or review a REST or GraphQL API — resource modeling, versioning strategy, error contract, OpenAPI/schema-first workflow, and security baseline
compatibility: ">=0.7.0"
---

# API Design

> Skill metadata: version "1.0"; license MIT; tags [api, rest, graphql, openapi, design]; compatibility ">=0.7.0"; recommended tools [codebase, editFiles, runCommands].

Design a new API or review an existing one for consistency, versioning, security, and documentation. Produces an OpenAPI 3.1 spec or GraphQL schema as the source of truth.

## When to use

- User asks to "design an API", "review my endpoints", "add OpenAPI docs", "write a GraphQL schema"
- A new service needs a public or internal API contract
- Inconsistencies found in an existing API (mixed conventions, missing error shapes)

## When not to use

- Internal RPC between services that will never be public or consumed by external clients
- Existing API with stable consumers — breaking changes need a separate migration plan

## Steps

### 1. Clarify the API surface

Ask if not obvious:

- **Consumers**: browser SPA, mobile app, third-party developers, internal services?
- **Style**: REST, GraphQL, or both?
- **Authentication**: JWT bearer, API key, OAuth2, mTLS?
- **Versioning preference**: URL path (`/v1/`), header (`Accept-Version`), or none?

### 2. Model resources (REST) or schema (GraphQL)

**REST — resource identification:**

Nouns, not verbs. Collections and items:

```
GET    /orders          → list orders
POST   /orders          → create order
GET    /orders/{id}     → get order
PATCH  /orders/{id}     → partial update
DELETE /orders/{id}     → delete order
```

Nested resources only one level deep:

```
GET /orders/{id}/items  ✓
GET /orders/{id}/items/{itemId}/details  ✗  (flatten to /order-items/{id})
```

**GraphQL — type-first design:**

```graphql
type Order {
  id: ID!
  status: OrderStatus!
  items: [OrderItem!]!
  createdAt: DateTime!
}

type Query {
  order(id: ID!): Order
  orders(filter: OrderFilter, pagination: PaginationInput): OrderConnection!
}

type Mutation {
  createOrder(input: CreateOrderInput!): CreateOrderPayload!
  updateOrderStatus(id: ID!, status: OrderStatus!): UpdateOrderPayload!
}
```

### 3. Define the error contract

Consistent error responses prevent client surprises.

**REST (RFC 7807 Problem Details):**

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 422,
  "detail": "The 'email' field must be a valid email address.",
  "instance": "/orders/create",
  "errors": [
    { "field": "email", "message": "invalid email format" }
  ]
}
```

Standard status codes:
- `200 OK` — success with body
- `201 Created` — resource created (`Location` header required)
- `204 No Content` — success, no body
- `400 Bad Request` — client input error
- `401 Unauthorized` — missing/invalid auth
- `403 Forbidden` — authenticated but not permitted
- `404 Not Found` — resource does not exist
- `409 Conflict` — state conflict (e.g., duplicate)
- `422 Unprocessable Entity` — validation failure
- `429 Too Many Requests` — rate limited (`Retry-After` header required)
- `500 Internal Server Error` — never expose internal details

**GraphQL errors:**

```json
{
  "errors": [
    {
      "message": "Order not found",
      "extensions": { "code": "NOT_FOUND", "orderId": "abc123" }
    }
  ]
}
```

### 4. Write the OpenAPI 3.1 spec (REST)

Schema-first: write the spec before the implementation.

```yaml
openapi: "3.1.0"
info:
  title: Orders API
  version: "1.0.0"
paths:
  /orders:
    post:
      summary: Create an order
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateOrderRequest'
      responses:
        '201':
          description: Order created
          headers:
            Location:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
        '422':
          $ref: '#/components/responses/ValidationError'
```

Validate the spec:

```bash
npx @redocly/cli lint openapi.yaml
# or
npx swagger-cli validate openapi.yaml
```

### 5. Security baseline

Every API must have:

| Control | Implementation |
|---------|---------------|
| Authentication | JWT bearer (`Authorization: Bearer <token>`) or API key |
| HTTPS only | Reject HTTP at load balancer; HSTS header |
| Input validation | Validate all input against schema; reject unknown fields |
| Rate limiting | `429` + `Retry-After`; per-user and per-IP limits |
| CORS | Allowlist origins; never `*` for credentialed requests |
| Sensitive data | Never expose passwords, internal IDs, or PII in error messages |

### 6. Versioning strategy

| Strategy | When to use | Trade-off |
|----------|------------|-----------|
| URL path `/v1/` | Public APIs, long-lived | Simple, cacheable; requires routing duplication |
| `Accept: application/vnd.api+json;version=1` | API-first teams | Clean URL; harder to test in browser |
| No versioning + additive-only policy | Internal APIs, single consumer | Simplest; requires discipline |

Additive-only rule: adding fields, endpoints, and optional parameters is non-breaking. Removing or renaming is always breaking.

### 7. Review checklist

- [ ] Resources use nouns, not verbs
- [ ] Consistent naming convention (camelCase or snake_case — pick one)
- [ ] All endpoints have documented error responses
- [ ] Pagination on all collection endpoints (`cursor` or `page`/`limit`)
- [ ] OpenAPI/GraphQL schema is the source of truth, not auto-generated from code
- [ ] Authentication required on all non-public endpoints
- [ ] No sensitive data in URL path (use body or header)

## Verify

- [ ] OpenAPI spec validates with zero errors (`redocly lint` or `swagger-cli validate`)
- [ ] Error contract is consistent across all endpoints
- [ ] Security baseline (auth, HTTPS, rate limiting) is addressed
- [ ] Breaking change policy documented
